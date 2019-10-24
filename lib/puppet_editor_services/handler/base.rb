# frozen_string_literal: true

module PuppetEditorServices
  module Handler
    class Base
      attr_reader :protocol

      def initialize(protocol)
        @protocol = protocol
      end

      # @abstract
      def handle(message); end
    end
  end
end
