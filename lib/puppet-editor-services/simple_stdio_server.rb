# frozen_string_literal: true

module PuppetEditorServices
  class SimpleSTDIOServerConnection < SimpleServerConnectionBase
    attr_accessor :simple_stdio_server

    def initialize(simple_stdio_server)
      @simple_stdio_server = simple_stdio_server
    end

    def send_data(data)
      $editor_services_stdout.write(data) # rubocop:disable Style/GlobalVars  We need this global var
      true
    end

    def close_connection_after_writing
      $editor_services_stdout.flush # rubocop:disable Style/GlobalVars  We need this global var
      @simple_stdio_server.close_connection
      true
    end

    def close_connection
      @simple_stdio_server.close_connection
      true
    end
  end

  class SimpleSTDIOServer < SimpleServerConnectionBase
    attr_accessor :exiting

    def log(message)
      PuppetEditorServices.log_message(:debug, "STDIOSRV: #{message}")
    end

    def initialize
      @exiting = false
    end

    def start(handler_klass = PuppetEditorServices::SimpleServerConnectionHandler, handler_options = {}, _server_options = {})
      # server_options[:servicename] = 'LANGUAGE SERVER' if server_options[:servicename].nil?
      # This is a little heavy handed but we need to suppress writes to STDOUT and STDERR
      $VERBOSE = nil
      # Some libraries use $stdout to write to the console. Suppress all of that too!
      # Copy the existing $stdout variable and then reassign to NUL to suppress it
      $editor_services_stdout = $stdout # rubocop:disable Style/GlobalVars  We need this global var
      $stdout = File.open(File::NULL, 'w')

      $editor_services_stdout.sync = true # rubocop:disable Style/GlobalVars  We need this global var
      # Stop the stupid CRLF injection when on Windows
      $editor_services_stdout.binmode unless $editor_services_stdout.binmode # rubocop:disable Style/GlobalVars  We need this global var

      @handler = handler_klass.new(handler_options)
      client_connection = PuppetEditorServices::SimpleSTDIOServerConnection.new(self)
      @handler.client_connection = client_connection
      @handler.post_init

      log('Starting STDIO server...')
      loop do
        inbound_data = nil
        read_from_pipe($stdin, 2) { |data| inbound_data = data }
        break if @exiting
        @handler.receive_data(inbound_data) unless inbound_data.nil?
        break if @exiting
      end
      log('STDIO server stopped')
    end

    def stop
      log('Stopping STDIO server...')
      @exiting = true
    end

    def client_handler(handler_id)
      @handler unless @handler.nil? || @handler.handler_id != handler_id
    end

    def close_connection
      stop
    end

    def pipe_is_readable?(stream, timeout = 0.5)
      read_ready = IO.select([stream], [], [], timeout)
      read_ready && stream == read_ready[0][0]
    end

    def read_from_pipe(pipe, timeout = 0.1, &_block)
      if pipe_is_readable?(pipe, timeout)
        l = nil
        begin
          l = pipe.readpartial(4096)
        rescue EOFError
          log('Reading from pipe has reached End of File.  Exiting STDIO server')
          stop
        rescue # rubocop:disable Style/RescueStandardError, Lint/HandleExceptions
          # Any errors here should be swallowed because the pipe could be in any state
        end
        # since readpartial may return a nil at EOF, skip returning that value
        # client_connected = true unless l.nil?
        yield l unless l.nil?
      end
      nil
    end
  end
end
