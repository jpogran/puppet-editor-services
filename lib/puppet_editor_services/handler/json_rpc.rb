# frozen_string_literal: true

require 'puppet_editor_services/handler/base'

module PuppetEditorServices
  module Handler
    class JsonRPC < ::PuppetEditorServices::Handler::Base
      # TODO: This is broken
      #attr_reader :connection_handler
      #attr_reader :handler_creation_options

      def initialize(protocol)
        super(protocol)
        # @connection_handler = connection_handler
        # @handler_creation_options = options.nil? ? {} : options.dup
      end

      # options
      #    source        :request, :notification etc.
      #    message       Message that caused the error
      # @abstract
      def unhandled_exception(error, options)
        PuppetEditorServices.log_message(:error, "Unhandled exception from #{options[:source]}. JSON Message #{options[:raw_object]}: #{error.inspect}\n#{error.backtrace}")
      end

      def handle(json_rpc_message)
        case json_rpc_message

        when ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage
          method_name = rpc_name_to_ruby_method_name('request', json_rpc_message.rpc_method)
          if self.respond_to?(method_name.intern)
            begin
              # TODO BROKEN!!
              encode_and_send(
                JSONMessage.reply_result(
                  raw_object, self.send(method_name, protocol.connection.id, json_rpc_message)
                )
              )
            rescue StandardError => e
              self.unhandled_exception(e, :source => :request, :raw_object => raw_object)
            end
            return true
          end

          # TODO BROKEN!!
          # Default processing
          encode_and_send(JSONMessage.reply_method_not_found(raw_object))
          PuppetEditorServices.log_message(:error, "Unknown RPC method #{rpc_method}")
        else
          PuppetEditorServices.log_message(:error, "Unknown JSON RPC message type #{json_rpc_message.class}")
        end

        puts ""
      end

      private

      # # Route message to the correct handler
      # def route_request(raw_object, rpc_method, params)
      #   false
      # end

      def route_notification(raw_object, rpc_method, params)
        method_name = rpc_name_to_ruby_method_name('notification', rpc_method)

        if self.respond_to?(method_name.intern)
          begin
            self.send(method_name, handler_id, raw_object, params)
          rescue StandardError => e
            self.unhandled_exception(e, :source => :notification, :raw_object => raw_object)
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
        if self.respond_to?(method_name.intern)
          begin
            return self.send(method_name, handler_id, raw_object, original_request)
          rescue StandardError => e
            self.unhandled_exception(e, :source => :response, :raw_object => raw_object)
          end
          return true
        end

        # Default processing
        PuppetEditorServices.log_message(:error, "Unknown RPC response for method #{original_request['method']}")
        false
      end

      # TODO: Add example for a request, notification and response

      def rpc_name_to_ruby_method_name(prefix, rpc_name)
        name = prefix + '_' + rpc_name.tr('/', '_').tr('$', 'dollar').downcase
        name
      end
    end
  end
end
