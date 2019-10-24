# frozen_string_literal: true

#require 'puppet-editor-services/json_rpc_handler'

module PuppetEditorServices
  module Protocol
    module JsonRPCMessages
      # Protocol message primitives
      class Message
        attr_accessor :jsonrpc

        def initialize(initial_hash = nil)
          if initial_hash.nil?
            jsonrpc = JSONRPC_VERSION
          else
            from_h!(initial_hash)
          end
        end

        def from_h!(value)
          value = {} if value.nil?
          self.jsonrpc = value['jsonrpc']
          self
        end

        def to_json(*options)
          to_h.to_json(options)
        end

        def to_h
          {
            'jsonrpc' => jsonrpc
          }
        end
      end

      # interface RequestMessage extends Message {
      #   /**
      #    * The request id.
      #    */
      #   id: number | string;
      #   /**
      #    * The method to be invoked.
      #    */
      #   method: string;
      #   /**
      #    * The method's params.
      #    */
      #   params?: Array<any> | object;
      # }
      class RequestMessage < Message
        attr_accessor :id
        attr_accessor :rpc_method
        attr_accessor :params

        def initialize(initial_hash = nil)
          super
        end

        def from_h!(value)
          value = {} if value.nil?
          super(value)
          self.id = value['id']
          self.rpc_method = value['method']
          self.params = value['params']
          self
        end

        def to_h
          super.merge({
            'id' => id,
            'method' => rpc_method,
            'params' => params
          })
        end
      end
    end
  end
end


#   module JSONMessage
#     def self.reply_result(raw_request, result)
#       {
#         KEY_JSONRPC => VALUE_VERSION,
#         KEY_ID      => raw_request[KEY_ID],
#         KEY_RESULT  => result
#       }
#     end

#     def self.reply_error(raw_request, code, message)
#       {
#         KEY_JSONRPC => VALUE_VERSION,
#         KEY_ID      => raw_request[KEY_ID],
#         KEY_ERROR   => {
#           KEY_CODE    => code,
#           KEY_MESSAGE => message
#         }
#       }
#     end

#     def self.reply_method_not_found(raw_request, message = nil)
#       reply_error(raw_request, CODE_METHOD_NOT_FOUND, message || MSG_METHOD_NOT_FOUND)
#     end

#     def self.notification(method_name, params)
#       {
#         KEY_JSONRPC => VALUE_VERSION,
#         KEY_METHOD  => method_name,
#         KEY_PARAMS  => params
#       }
#     end

#     def self.response_succesful?(raw_object)
#       raw_object.key?('result')
#     end
#   end
# end
