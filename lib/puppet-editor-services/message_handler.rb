# frozen_string_literal: true

module PuppetEditorServices
  class BaseMessageHandler
    attr_reader :connection_handler
    attr_reader :handler_creation_options

    def initialize(connection_handler, options = {})
      @connection_handler = connection_handler
      @handler_creation_options = options.dup
    end

    # @abstract
    def unhandled_exception(error, options)
      PuppetEditorServices.log_message(:error, "Unhandled exception from #{options[:source]}. JSON Message #{options[:raw_object]}: #{error.inspect}\n#{error.backtrace}")
    end

    # TODO: Add example for a request, notification and response
  end
end
