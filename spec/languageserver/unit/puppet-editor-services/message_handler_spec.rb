require 'spec_helper'

describe 'PuppetLanguageServer::BaseMessageHandler' do
  let(:subject_options) {{ 'abc' => 123 }}
  let(:connection_handler) { MockJSONRPCHandler.new }
  let(:subject) { PuppetEditorServices::BaseMessageHandler.new(connection_handler, subject_options) }

  describe '.connection_handler' do
    it 'should be the same handler as at object creation' do
      expect(subject.connection_handler).to eq(connection_handler)
    end
  end

  describe '.handler_creation_options' do
    it 'should be the same options as at object creation' do
      expect(subject.handler_creation_options).to eq(subject_options)
    end
  end

  describe '.unhandled_exception' do
    it 'should respond to unhandled_exception' do
      expect(subject.respond_to?(:unhandled_exception)).to be(true)
    end
  end
end
