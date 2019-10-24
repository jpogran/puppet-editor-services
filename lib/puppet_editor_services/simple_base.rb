# # frozen_string_literal: true

# module PuppetEditorServices
#   class SimpleServer
#     def self.current_server
#       @@current_server # rubocop:disable Style/ClassVars  This is fine
#     end

#     def self.current_server=(value)
#       @@current_server = value # rubocop:disable Style/ClassVars  This is fine
#     end

#     def initialize(*_)
#       # Assumes there's only ONE active simpler server running at a time.
#       PuppetEditorServices::SimpleServer.current_server = self
#     end

#     # TODO: abstract
#     # Returns a client connection handler for a given handler_id
#     def client_handler(handler_id); end
#   end

#   class SimpleServerConnectionBase
#     # Override this method
#     # @api public
#     def error?
#       false
#     end

#     # Override this method
#     # @api public
#     def send_data(_data)
#       false
#     end

#     # Override this method
#     # @api public
#     def close_connection_after_writing
#       true
#     end

#     # Override this method
#     # @api public
#     def close_connection
#       true
#     end
#   end

#   class SimpleServerConnectionHandler
#     attr_accessor :client_connection

#     def initialize(client_connection, *_)
#       @client_connection = client_connection
#     end

#     # Override this method
#     # @api public
#     def receive_data(_data)
#       false
#     end

#     # Override this method
#     # @api public
#     def post_init
#       true
#     end

#     # Override this method
#     # @api public
#     def unbind
#       true
#     end

#     def handler_id
#       object_id.to_s
#     end
#   end
# end
