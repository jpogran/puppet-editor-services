# frozen_string_literal: true

require 'puppet-editor-services/json_rpc_handler'

module PuppetEditorServices
  module JSONMessage
    def self.reply_result(raw_request, result)
      {
        KEY_JSONRPC => VALUE_VERSION,
        KEY_ID      => raw_request[KEY_ID],
        KEY_RESULT  => result
      }
    end

    def self.reply_error(raw_request, code, message)
      {
        KEY_JSONRPC => VALUE_VERSION,
        KEY_ID      => raw_request[KEY_ID],
        KEY_ERROR   => {
          KEY_CODE    => code,
          KEY_MESSAGE => message
        }
      }
    end

    def self.reply_method_not_found(raw_request, message = nil)
      reply_error(raw_request, CODE_METHOD_NOT_FOUND, message || MSG_METHOD_NOT_FOUND)
    end

    def self.notification(method_name, params)
      {
        KEY_JSONRPC => VALUE_VERSION,
        KEY_METHOD  => method_name,
        KEY_PARAMS  => params
      }
    end

    def self.response_succesful?(raw_object)
      raw_object.key?('result')
    end
  end
end
