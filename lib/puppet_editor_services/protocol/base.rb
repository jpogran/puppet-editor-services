# frozen_string_literal: true

module PuppetEditorServices
  module Protocol
    class Base
      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def protocol_options
        connection.server.protocol_options
      end
    end
  end
end
