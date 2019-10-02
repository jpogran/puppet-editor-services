require 'spec_helper'

describe 'PuppetEditorServices::JSONRPCHandler' do
  let(:connection) { MockConnection.new }
  let(:handler_options) do
    { :message_handler_class => MockMessageHandler }
  end
  # This isn't the best, but the variable isn't exposed
  let(:message_handler) { subject.instance_variable_get(:@message_handler) }
  let(:subject) { PuppetEditorServices::JSONRPCHandler.new(connection, handler_options) }

  context 'Given a valid JSON Request string' do
    let(:data) { "Content-Length: 67\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"method":"puppet/getVersion","params":null}' }

    it 'should call the appropriate request method on the message handler' do
      expect(message_handler).to receive(:request_puppet_getversion)
      subject.receive_data(data)
    end
  end

  context 'Given a valid JSON Notification string' do
    let(:data) { "Content-Length: 52\r\n\r\n" + '{"jsonrpc":"2.0","method":"initialized","params":{}}' }

    it 'should call the appropriate notification method on the message handler' do
      expect(message_handler).to receive(:notification_initialized)
      subject.receive_data(data)
    end
  end

  context 'Given a valid JSON Response string' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should call the appropriate response method on the message handler' do
      # Force the request id to what we want to test for.
      allow(subject).to receive(:client_request_id!).and_return(1)
      # Send a request to the client
      subject.send_client_request('mock', {})
      # Mimic a repsonse from the client
      expect(message_handler).to receive(:response_mock)
      subject.receive_data(data)
    end
  end

  context 'Given a JSON Response that has no matching request from the server' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should ignore the response' do
      expect(subject).to_not receive(:route_request)
      expect(subject).to_not receive(:route_notification)
      expect(subject).to_not receive(:route_response)
      subject.receive_data(data)
    end
  end

  context 'Given a JSON Response that appears twice' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should call the appropriate response method on the message handler only once' do
      # Force the request id to what we want to test for.
      allow(subject).to receive(:client_request_id!).and_return(1)
      # Send a request to the client
      subject.send_client_request('mock', {})
      # Mimic a repsonse from the client, only once
      expect(subject).to_not receive(:route_request)
      expect(subject).to_not receive(:route_notification)
      expect(message_handler).to receive(:response_mock).once
      subject.receive_data(data)
      subject.receive_data(data)
    end
  end
end
