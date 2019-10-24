# frozen_string_literal: true

require 'json'
require 'puppet_editor_services/logging'
require 'puppet_editor_services/protocol/base'

module PuppetEditorServices
  module Protocol
    class JsonRPC < PuppetEditorServices::Protocol::Base
      CODE_INVALID_JSON       = -32700
      MSG_INVALID_JSON        = 'invalid JSON'

      CODE_INVALID_REQUEST    = -32600
      MSG_INVALID_REQ_JSONRPC = "invalid request: doesn't include \"jsonrpc\": \"2.0\""
      MSG_INVALID_REQ_ID      = 'invalid request: wrong id'
      MSG_INVALID_REQ_METHOD  = 'invalid request: wrong method'
      MSG_INVALID_REQ_PARAMS  = 'invalid request: wrong params'

      CODE_METHOD_NOT_FOUND   = -32601
      MSG_METHOD_NOT_FOUND    = 'method not found'

      CODE_INVALID_PARAMS     = -32602
      MSG_INVALID_PARAMS      = 'invalid parameter(s)'

      CODE_INTERNAL_ERROR     = -32603
      MSG_INTERNAL_ERROR      = 'internal error'

      PARSING_ERROR_RESPONSE  = '{"jsonrpc":"2.0","id":null,"error":{' \
                                "\"code\":#{CODE_INVALID_JSON}," \
                                "\"message\":\"#{MSG_INVALID_JSON}\"}}"

      BATCH_NOT_SUPPORTED_RESPONSE = '{"jsonrpc":"2.0","id":null,"error":{' \
                                      '"code":-32099,' \
                                      '"message":"batch mode not implemented"}}'

      KEY_JSONRPC   = 'jsonrpc'
      VALUE_VERSION = '2.0'
      KEY_ID        = 'id'
      KEY_METHOD    = 'method'
      KEY_PARAMS    = 'params'
      KEY_RESULT    = 'result'
      KEY_ERROR     = 'error'
      KEY_CODE      = 'code'
      KEY_MESSAGE   = 'message'

      def initialize(connection)
        super(connection)

        options = protocol_options

        @state = :data
        @buffer = []

        # TODO: BROKEN
        @message_handler = nil
        # if options[:message_handler_class].nil?
        #   @message_handler = PuppetEditorServices::BaseMessageHandler.new(self, options)
        # else
        #   @message_handler = options[:message_handler_class].new(self, options)
        # end
        # TODO: Do I need this? @message_handler.json_rpc_handler = self

        @request_sequence_id = 0
        @requests = {}
        @request_mutex = Mutex.new
      end

      # From PuppetEditorServices::SimpleServerConnectionHandler
      def post_init
        PuppetEditorServices.log_message(:info, 'Client has connected to the RPC server')
      end

      # From PuppetEditorServices::SimpleServerConnectionHandler
      def unbind
        PuppetEditorServices.log_message(:info, 'Client has disconnected from the RPC server')
      end

      def extract_headers(raw_header)
        header = {}
        raw_header.split("\r\n").each do |item|
          name, value = item.split(':', 2)

          if name.casecmp('Content-Length').zero?
            header['Content-Length'] = value.strip.to_i
          elsif name.casecmp('Content-Type').zero?
            header['Content-Length'] = value.strip
          else
            raise("Unknown header #{name} in JSON message")
          end
        end
        header
      end

      # From PuppetEditorServices::SimpleServerConnectionHandler
      def receive_data(data)
        # Inspired by https://github.com/PowerShell/PowerShellEditorServices/blob/dba65155c38d3d9eeffae5f0358b5a3ad0215fac/src/PowerShellEditorServices.Protocol/MessageProtocol/MessageReader.cs
        return if data.empty?
        return if @state == :ignore

        # TODO: Thread/Atomic safe? probably not
        @buffer += data.bytes.to_a

        while @buffer.length > 4
          # Check if we have enough data for the headers
          # Need to find the first instance of '\r\n\r\n'
          offset = 0
          while offset < @buffer.length - 4
            break if @buffer[offset] == 13 && @buffer[offset + 1] == 10 && @buffer[offset + 2] == 13 && @buffer[offset + 3] == 10
            offset += 1
          end
          return unless offset < @buffer.length - 4

          # Extract the headers
          raw_header = @buffer.slice(0, offset).pack('C*').force_encoding('ASCII') # Note the headers are always ASCII encoded
          headers = extract_headers(raw_header)
          raise('Missing Content-Length header') if headers['Content-Length'].nil?

          # Now we have the headers and the content length, do we have enough data now
          minimum_buf_length = offset + 3 + headers['Content-Length'] + 1 # Need to add one as we're converting from offset (zero based) to length (1 based) arrays
          return if @buffer.length < minimum_buf_length

          # Extract the message content
          content = @buffer.slice(offset + 3 + 1, headers['Content-Length']).pack('C*').force_encoding('utf-8') # TODO: default is utf-8.  Need to enode based on Content-Type
          # Purge the buffer
          @buffer = @buffer.slice(minimum_buf_length, @buffer.length - minimum_buf_length)
          @buffer = [] if @buffer.nil?

          PuppetEditorServices.log_message(:debug, "--- INBOUND\n#{content}\n---")
          process_parsed_object(::JSON.parse(content))
        end
      end

      def send_json_string(string)
        PuppetEditorServices.log_message(:debug, "--- OUTBOUND\n#{string}\n---")

        size = string.bytesize if string.respond_to?(:bytesize)
        @client_connection.send_data "Content-Length: #{size}\r\n\r\n" + string
      end

      def encode_and_send(object)
        send_json_string(::JSON.generate(object))
      end

      # Seperate method so async JSON processing can be supported.
      def process_parsed_object(obj)
puts obj
return
        return process_message(obj) if obj.is_a?(Hash)
        return unless obj.is_a?(Array)
        # Batch: multiple requests/notifications in an array.
        # NOTE: Not implemented as it doesn't make sense using JSON RPC over pure TCP / UnixSocket.
        batch_not_supported_error obj
        send_json_string BATCH_NOT_SUPPORTED_RESPONSE
        close_connection_after_writing
        @state = :ignore
      end

      def process_message(obj)
        unless obj[KEY_JSONRPC] == '2.0'
          invalid_request obj, CODE_INVALID_REQUEST, MSG_INVALID_REQ_JSONRPC
          reply_error id, CODE_INVALID_REQUEST, MSG_INVALID_REQ_JSONRPC
          return false
        end

        # Requests must have an ID and Method
        is_request = obj.key?(KEY_ID) && obj.key?(KEY_METHOD)
        # Notifications must have a Method but no ID
        is_notification = obj.key?(KEY_METHOD) && !obj.key?(KEY_ID)
        # Responses must have an ID, no Method but one of Result or Error
        is_response = obj.key?(KEY_ID) && !obj.key?(KEY_METHOD) && (obj.key?(KEY_RESULT) || obj.key?(KEY_ERROR))

        if (params = obj[KEY_PARAMS])
          unless params.is_a?(Array) || params.is_a?(Hash)
            invalid_request obj, CODE_INVALID_REQUEST, MSG_INVALID_REQ_PARAMS
            reply_error id, CODE_INVALID_REQUEST, MSG_INVALID_REQ_PARAMS
            return false
          end
        end

        id = obj[KEY_ID]
        # Requests and Responses must have an ID that is either a string or integer
        if is_request || is_response
          unless id.is_a?(String) || id.is_a?(Integer)
            invalid_request obj, CODE_INVALID_REQUEST, MSG_INVALID_REQ_ID
            reply_error nil, CODE_INVALID_REQUEST, MSG_INVALID_REQ_ID
            return false
          end
        end

        # Requests and Notifications must have a method
        if is_request || is_notification
          unless (obj[KEY_METHOD]).is_a? String
            invalid_request obj, CODE_INVALID_REQUEST, MSG_INVALID_REQ_METHOD
            reply_error id, CODE_INVALID_REQUEST, MSG_INVALID_REQ_METHOD
            return false
          end
        end

        # Responses must have a matching request originating from this JSON Handler
        # Otherwise ignore it
        if is_response
          original_request = client_request!(obj[KEY_ID])
          return false if original_request.nil?
        end

        if is_request
          route_request(obj, obj[KEY_METHOD], obj[KEY_PARAMS])
          return true
        elsif is_notification
          route_notification(obj, obj[KEY_METHOD], obj[KEY_PARAMS])
          return true
        elsif is_response
          route_response(obj, original_request)
          return true
        end
        false
      end

      def close_connection
        client_connection.close_connection unless client_connection.nil?
      end

      def connection_error?
        return false if client_connection.nil?
        client_connection.error?
      end

      # def encode_json(data)
      #   JSON.generate(data)
      # end

      # Message generation should be in a separate module
      # def reply_error(id, code, message)
      #   encode_and_send(KEY_JSONRPC => VALUE_VERSION,
      #                             KEY_ID      => id,
      #                             KEY_ERROR   => {
      #                               KEY_CODE    => code,
      #                               KEY_MESSAGE => message
      #                             })
      # end

      # Route message to the correct handler
      def route_request(raw_object, rpc_method, params)
        method_name = rpc_name_to_ruby_method_name('request', rpc_method)
        if @message_handler.respond_to?(method_name.intern)
          begin
            encode_and_send(JSONMessage.reply_result(raw_object, @message_handler.send(method_name, handler_id, raw_object, params)))
          rescue StandardError => e
            @message_handler.unhandled_exception(e, :source => :request, :raw_object => raw_object)
          end
          return true
        end

        # Default processing
        encode_and_send(JSONMessage.reply_method_not_found(raw_object))
        PuppetEditorServices.log_message(:error, "Unknown RPC method #{rpc_method}")
        false
      end

      def route_notification(raw_object, rpc_method, params)
        method_name = rpc_name_to_ruby_method_name('notification', rpc_method)

        if @message_handler.respond_to?(method_name.intern)
          begin
            @message_handler.send(method_name, handler_id, raw_object, params)
          rescue StandardError => e
            @message_handler.unhandled_exception(e, :source => :notification, :raw_object => raw_object)
          end
          return true
        end

        # Default processing
        if rpc_method.start_with?('$/')
          PuppetEditorServices.log_message(:debug, "Ignoring RPC notification #{rpc_method}")
        else
          PuppetEditorServices.log_message(:error, "Unknown RPC notification #{rpc_method}")
        end
        false
      end

      def route_response(raw_object, original_request)
        unless ::PuppetEditorServices::JSONMessage.response_succesful?(raw_object) # rubocop:disable Style/IfUnlessModifier Line is too long otherwise
          PuppetEditorServices.log_message(:error, "Response for method '#{original_request['method']}' with id '#{original_request['id']}' failed with #{raw_object['error']}")
        end
        method_name = rpc_name_to_ruby_method_name('response', original_request['method'])
        if @message_handler.respond_to?(method_name.intern)
          begin
            return @message_handler.send(method_name, handler_id, raw_object, original_request)
          rescue StandardError => e
            @message_handler.unhandled_exception(e, :source => :response, :raw_object => raw_object)
          end
          return true
        end

        # Default processing
        PuppetEditorServices.log_message(:error, "Unknown RPC response for method #{original_request['method']}")
        false
      end

      # TODO: Add the request methods and wrap json rpc calls?

      # TODO: private
      def rpc_name_to_ruby_method_name(prefix, rpc_name)
        name = prefix + '_' + rpc_name.tr('/', '_').tr('$', 'dollar').downcase
        name
      end
      #-------------

      # def reply_diagnostics(uri, diagnostics)
      #   return nil if connection_error?

      #   response = {
      #     KEY_JSONRPC => VALUE_VERSION,
      #     KEY_METHOD  => 'textDocument/publishDiagnostics',
      #     KEY_PARAMS  => { 'uri' => uri, 'diagnostics' => diagnostics }
      #   }

      #   send_json_string(encode_json(response))
      #   true
      # end

      # def send_show_message_notification(msg_type, message)
      #   response = {
      #     KEY_JSONRPC => VALUE_VERSION,
      #     KEY_METHOD  => 'window/showMessage',
      #     KEY_PARAMS  => { 'type' => msg_type, 'message' => message }
      #   }

      #   send_json_string(encode_json(response))
      #   true
      # end

      # TODO: Is this really needed?
      def parsing_error(_data, exception)
        PuppetEditorServices.log_message(:error, "parsing error:\n#{exception.message}")
      end

      # TODO: Is this really needed?
      def batch_not_supported_error(_obj)
        PuppetEditorServices.log_message(:error, 'batch request received but not implemented')
      end

      # TODO: Is this really needed?
      def invalid_request(_obj, code, message = nil)
        PuppetEditorServices.log_message(:error, "error #{code}: #{message}")
      end

      # region Server-to-Client request/response methods
      def send_client_request(rpc_method, params)
        req_id = client_request_id!
        request = {
          KEY_JSONRPC => VALUE_VERSION,
          KEY_ID      => req_id,
          KEY_METHOD  => rpc_method,
          KEY_PARAMS  => params
        }
        encode_and_send(request)
        add_client_request(req_id, request)
        req_id
      end

      # Thread-safe way to get a new request id
      def client_request_id!
        value = nil
        @request_mutex.synchronize do
          value = @request_sequence_id
          @request_sequence_id += 1
        end
        value
      end

      # Stores the request so it can later be correlated with an
      # incoming repsonse
      def add_client_request(id, request)
        @request_mutex.synchronize do
          @requests[id] = request
        end
      end

      # Retrieve the request to a client. Note that this removes it
      # from the requests queue.
      def client_request!(id)
        value = nil
        @request_mutex.synchronize do
          unless @requests[id].nil?
            value = @requests[id]
            @requests.delete(id)
          end
        end
        value
      end
      # endregion

      # # TODO Need to modify this for a Notification and Response
      # class Request
      #   attr_reader :rpc_method, :params, :id

      #   def initialize(json_rpc_handler, id, rpc_method, params)
      #     @json_rpc_handler = json_rpc_handler
      #     @id = id
      #     @rpc_method = rpc_method
      #     @params = params
      #   end

      #   def reply_result(result)
      #     return nil if @json_rpc_handler.connection_error?

      #     response = {
      #       KEY_JSONRPC => VALUE_VERSION,
      #       KEY_ID      => @id,
      #       KEY_RESULT  => result
      #     }

      #     @json_rpc_handler.send_json_string(@json_rpc_handler.encode_json(response))
      #     true
      #   end

      #   def reply_internal_error(message = nil)
      #     return nil if @json_rpc_handler.connection_error?
      #     @json_rpc_handler.reply_error(@id, CODE_INTERNAL_ERROR, message || MSG_INTERNAL_ERROR)
      #   end

      #   def reply_method_not_found(message = nil)
      #     return nil if @json_rpc_handler.connection_error?
      #     @json_rpc_handler.reply_error(@id, CODE_METHOD_NOT_FOUND, message || MSG_METHOD_NOT_FOUND)
      #   end

      #   def reply_invalid_params(message = nil)
      #     return nil if @json_rpc_handler.connection_error?
      #     @json_rpc_handler.reply_error(@id, CODE_INVALID_PARAMS, message || MSG_INVALID_PARAMS)
      #   end

      #   def reply_custom_error(code, message)
      #     return nil if @json_rpc_handler.connection_error?
      #     unless code.is_a?(Integer) && (-32099..-32000).cover?(code) # rubocop:disablexxx Style/IfUnlessModifier  Nicer to read like this
      #       raise ArgumentError, 'code must be an integer between -32099 and -32000'
      #     end
      #     @json_rpc_handler.reply_error(@id, code, message)
      #   end
      # end
    end
  end
end
