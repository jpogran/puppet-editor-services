require 'spec_helper'

describe 'PuppetLanguageServer::MessageHandler' do
  MANIFEST_FILENAME = 'file:///something.pp'
  PUPPETFILE_FILENAME = 'file:///Puppetfile'
  EPP_FILENAME = 'file:///something.epp'
  UNKNOWN_FILENAME = 'file:///I_do_not_work.exe'
  ERROR_CAUSING_FILE_CONTENT = "file_content which causes errros\n <%- Wee!\n class 'foo' {'"

  let(:subject_options) {}
  let(:subject) { PuppetLanguageServer::MessageHandler.new(MockJSONRPCHandler.new, subject_options) }
  let(:connection_handler_id) { subject.connection_handler.handler_id }

  RSpec::Matchers.define :method_not_nil do |method_name|
    match { |actual| !actual.send(method_name).nil? }
  end

  RSpec::Matchers.define :server_capability do |name|
    match do |actual|
      actual['capabilities'] && actual['capabilities'][name]
    end
  end

  describe '#documents' do
    it 'should respond to documents method' do
      expect(subject).to respond_to(:documents)
    end
  end

  context 'When receiving a request' do
  #   let(:request_connection) { MockJSONRPCHandler.new() }
    let(:request_rpc_method) { nil }
    let(:request_params) { {} }
    let(:raw_request) do
      {
        'jsonrpc' => '2.0',
        'id'      => 1,
        'method'  => request_rpc_method,
        'params'  => request_params
      }
    end

  #   let(:request_id) { 0 }
  #   let(:request) do
  #     PuppetLanguageServer::JSONRPCHandler::Request.new(
  #       request_connection, request_id, request_rpc_method, request_params)
  #   end

    before(:each) do
      allow(PuppetLanguageServer).to receive(:log_message)
    end

  #   context 'given a request that raises an error' do
  #     let(:request_rpc_method) { 'puppet/getVersion' }
  #     before(:each) do
  #       expect(Puppet).to receive(:version).and_raise('MockError')
  #       allow(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
  #     end

  #     it 'should raise an error' do
  #       expect{ subject.receive_request(request) }.to raise_error(/MockError/)
  #     end

  #     it 'should call PuppetLanguageServer::CrashDump.write_crash_file' do
  #       expect(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
  #       expect{ subject.receive_request(request) }.to raise_error(/MockError/)
  #     end
  #   end

  #   context 'given a request that is protocol implementation dependant' do
  #     let(:request_rpc_method) { '$/MockRequest' }

  #     it 'should reply with an error' do
  #       expect(subject.json_rpc_handler).to receive(:reply_error).with(Object, PuppetLanguageServer::CODE_METHOD_NOT_FOUND, Object)
  #       subject.receive_request(request)
  #     end
  #   end

    # initialize - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#initialize
    describe '.request_initialize' do
      #context 'given an initialize request' do
      let(:request_rpc_method) { 'initialize' }
      let(:request_params) { { 'capabilities' => { 'cap1' => 'value1' } } }

      it 'should reply with capabilites' do
        expect(subject.request_initialize(connection_handler_id, raw_request, request_params)['capabilities']).to_not be_nil
      end

      it 'should save the client capabilities' do
        expect(subject.language_client).to receive(:parse_lsp_initialize!).with(request_params)
        subject.request_initialize(connection_handler_id, raw_request, request_params)
      end

      context 'when onTypeFormatting does support dynamic registration' do
        let(:request_params) do
          { 'capabilities' => {
              'textDocument' => {
                'onTypeFormatting' => {
                  'dynamicRegistration' => true
                }
              }
            }
          }
        end

        it 'should not statically register a documentOnTypeFormattingProvider' do
          expect(subject.request_initialize(connection_handler_id, raw_request, request_params)).to_not server_capability('documentOnTypeFormattingProvider')
        end
      end

      context 'when onTypeFormatting does not support dynamic registration' do
        let(:request_params) do
          { 'capabilities' => {
              'textDocument' => {
                'onTypeFormatting' => {
                  'dynamicRegistration' => false
                }
              }
            }
          }
        end

        it 'should statically register a documentOnTypeFormattingProvider' do
          expect(subject.request_initialize(connection_handler_id, raw_request, request_params)).to server_capability('documentOnTypeFormattingProvider')
        end
      end

      context 'when onTypeFormatting does not specify dynamic registration' do
        let(:request_params) { {} }

        it 'should statically register a documentOnTypeFormattingProvider' do
          expect(subject.request_initialize(connection_handler_id, raw_request, request_params)).to server_capability('documentOnTypeFormattingProvider')
        end
      end
    end

    # shutdown - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#shutdown
    describe '.request_shutdown' do
      let(:request_rpc_method) { 'shutdown' }
      it 'should reply with nil' do
        #expect(request).to receive(:reply_result).with(nil)

        expect(subject.request_shutdown(connection_handler_id, raw_request, request_params)).to be_nil
      end
    end

    describe '.request_puppet_getversion' do
      let(:request_rpc_method) { 'puppet/getVersion' }
      it 'should reply with the Puppet Version' do
        expect(subject.request_puppet_getversion(connection_handler_id, raw_request, request_params)).to method_not_nil(:puppetVersion)
      end
      it 'should reply with the Facter Version' do
        expect(subject.request_puppet_getversion(connection_handler_id, raw_request, request_params)).to method_not_nil(:facterVersion)
      end
      it 'should reply with the Language Server version' do
        expect(subject.request_puppet_getversion(connection_handler_id, raw_request, request_params)).to method_not_nil(:languageServerVersion)
      end
      it 'should reply with whether the facts are loaded' do
        expect(subject.request_puppet_getversion(connection_handler_id, raw_request, request_params)).to method_not_nil(:factsLoaded)
      end
      it 'should reply with whether the functions are loaded' do
        expect(subject.request_puppet_getversion(connection_handler_id, raw_request, request_params)).to method_not_nil(:functionsLoaded)
      end
      it 'should reply with whether the types are loaded' do
        expect(subject.request_puppet_getversion(connection_handler_id, raw_request, request_params)).to method_not_nil(:typesLoaded)
      end
    end

    describe '.request_puppet_getresource' do
      let(:request_rpc_method) { 'puppet/getResource' }
      let(:type_name) { 'user' }
      let(:title) { 'alice' }

      context 'and missing the typename' do
        let(:request_params) { {} }
        it 'should return an error string' do
          expect(subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)).to method_not_nil(:error)
        end
      end

      context 'and resource face returns nil' do
        let(:request_params) { {
          'typename' => type_name,
        } }

        it 'should return data with an empty string' do
          expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).and_return(nil)
          expect(subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)).to have_attributes(:data => '')
        end
      end

      context 'and only given a typename' do
        let(:request_params) { {
          'typename' => type_name,
        } }
        let(:resource_response) {
          result = PuppetLanguageServer::Sidecar::Protocol::ResourceList.new()
          result << random_sidecar_resource(type_name)
          result << random_sidecar_resource(type_name)
        }

        context 'and resource face returns empty array' do
          it 'should return data with an empty string' do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).and_return([])
            expect(subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)).to have_attributes(:data => '')
          end
        end

        context 'and resource face returns array with at least 2 elements' do
          before(:each) do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).with(type_name, nil, Object).and_return(resource_response)
          end

          it 'should call get_puppet_resource' do
            subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)
          end

          it 'should return data containing the type name' do
            expect(subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)).to have_attributes(:data => /#{type_name}/)
          end
        end
      end

      context 'and given a typename and title' do
        let(:request_params) { {
          'typename' => type_name,
          'title' => title,
        } }
        let(:resource_response) {
          result = PuppetLanguageServer::Sidecar::Protocol::ResourceList.new()
          result << random_sidecar_resource(type_name, title)
        }

        context 'and resource face returns nil' do
          it 'should return data with an empty string' do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).and_return(nil)
            expect(subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)).to have_attributes(:data => '')
          end
        end

        context 'and resource face returns a resource' do
          before(:each) do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).with(type_name, title, Object).and_return(resource_response)
          end

          it 'should call resource_face_get_by_typename' do
            subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)
          end

          it 'should return data containing the type name' do
            expect(subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)).to have_attributes(:data => /#{type_name}/)
          end

          it 'should return data containing the title' do
            expect(subject.request_puppet_getresource(connection_handler_id, raw_request, request_params)).to have_attributes(:data => /#{title}/)
          end
        end
      end
    end

    describe '.request_puppet_compilenodegraph' do
      let(:request_rpc_method) { 'puppet/compileNodeGraph' }
      let(:file_uri) { MANIFEST_FILENAME }
      let(:file_content) { 'some file content' }
      let(:dot_content) { 'some graph content' }
      let(:request_params) {{
        'external' => file_uri
      }}

      before(:each) do
        # Create fake document store
        subject.documents.clear
        subject.documents.set_document(file_uri,file_content, 0)
      end

      context 'and a file which is not a puppet manifest' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should reply with the error text' do
          expect(subject.request_puppet_compilenodegraph(connection_handler_id, raw_request, request_params)).to have_attributes(:error => /Files of this type/)
        end

        it 'should not reply with dotContent' do
          expect(subject.request_puppet_compilenodegraph(connection_handler_id, raw_request, request_params)).to_not have_attributes(:dotContent => /.+/)
        end
      end

      context 'and an error during generation of the node graph' do
        let(:mock_return) {
          value = PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new()
          value.dot_content = ''
          value.error_content = 'MockError'
          value
        }

        before(:each) do
          expect(PuppetLanguageServer::PuppetHelper).to receive(:get_node_graph).with(file_content, Object).and_return(mock_return)
        end

        it 'should reply with the error text' do
          expect(subject.request_puppet_compilenodegraph(connection_handler_id, raw_request, request_params)).to have_attributes(:error => /MockError/)
        end

        it 'should not reply with dotContent' do
          expect(subject.request_puppet_compilenodegraph(connection_handler_id, raw_request, request_params)).to have_attributes(:dotContent => '')
        end
      end

      context 'and successfully generate the node graph' do
        let(:mock_return) {
          value = PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new()
          value.dot_content = 'success'
          value.error_content = ''
          value
        }

        before(:each) do
          expect(PuppetLanguageServer::PuppetHelper).to receive(:get_node_graph).with(file_content, Object).and_return(mock_return)
        end

        it 'should reply with dotContent' do
          expect(subject.request_puppet_compilenodegraph(connection_handler_id, raw_request, request_params)).to have_attributes(:dotContent => /success/)
        end

        it 'should not reply with error' do
          expect(subject.request_puppet_compilenodegraph(connection_handler_id, raw_request, request_params)).to have_attributes(:error => '')
        end
      end
    end

    describe '.request_puppet_fixdiagnosticerrors' do
      let(:request_rpc_method) { 'puppet/fixDiagnosticErrors' }
      let(:file_uri) { MANIFEST_FILENAME }
      let(:return_content) { true }
      let(:file_content) { 'some file content' }
      let(:file_new_content) { 'some new file content' }
      let(:request_params) {{
        'documentUri' => file_uri,
        'alwaysReturnContent' => return_content
      }}

      before(:each) do
        # Create fake document store
        subject.documents.clear
        subject.documents.set_document(file_uri,file_content, 0)
      end

      context 'and a file which is not a puppet manifest' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to fixDiagnosticErrors/)
          subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)
        end

        it 'should reply with the document uri' do
          expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:documentUri => file_uri)
        end

        it 'should reply with no fixes applied' do
          expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:fixesApplied => 0)
        end

        context 'and return_content set to true' do
          let(:return_content) { true }

          it 'should reply with document content' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => file_content)
          end
        end

        context 'and return_content set to false' do
          let(:return_content) { false }

          it 'should reply with no document content' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => nil)
          end
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        context 'and an error during fixing the validation' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:fix_validate_errors).with(file_content).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)
            subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)
          end

          it 'should reply with the document uri' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:documentUri => file_uri)
          end

          it 'should reply with no fixes applied' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:fixesApplied => 0)
          end

          context 'and return_content set to true' do
            let(:return_content) { true }

            it 'should reply with document content' do
              expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => file_content)
            end
          end

          context 'and return_content set to false' do
            let(:return_content) { false }

            it 'should reply with no document content' do
              expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => nil)
            end
          end
        end

        context 'and succesfully fixes one or more validation errors' do
          let(:applied_fixes) { 1 }

          before(:each) do
            expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:fix_validate_errors).with(file_content).and_return([applied_fixes, file_new_content])
          end

          it 'should reply with the document uri' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:documentUri => file_uri)
          end

          it 'should reply with the number of fixes applied' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:fixesApplied => applied_fixes)
          end

          context 'and return_content set to true' do
            let(:return_content) { true }

            it 'should reply with document content' do
              expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => file_new_content)
            end
          end

          context 'and return_content set to false' do
            let(:return_content) { false }

            it 'should reply with document content' do
              expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => file_new_content)
            end
          end
        end

        context 'and succesfully fixes zero validation errors' do
          let(:applied_fixes) { 0 }

          before(:each) do
            expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:fix_validate_errors).with(file_content).and_return([applied_fixes, file_content])
          end

          it 'should reply with the document uri' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:documentUri => file_uri)
          end

          it 'should reply with the number of fixes applied' do
            expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:fixesApplied => applied_fixes)
          end

          context 'and return_content set to true' do
            let(:return_content) { true }

            it 'should reply with document content' do
              expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => file_content)
            end
          end

          context 'and return_content set to false' do
            let(:return_content) { false }

            it 'should reply with no document content' do
              expect(subject.request_puppet_fixdiagnosticerrors(connection_handler_id, raw_request, request_params)).to have_attributes(:newContent => nil)
            end
          end
        end
      end
    end

    # textDocument/completion - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#completion-request
    describe '.request_textdocument_completion' do
      let(:request_rpc_method) { 'textDocument/completion' }
      let(:line_num) { 1 }
      let(:char_num) { 2 }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => line_num,
          'character' => char_num,
        },
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide completion/)
          subject.request_textdocument_completion(connection_handler_id, raw_request, request_params)
        end

        it 'should reply with a complete, empty response' do
          expect(subject.request_textdocument_completion(connection_handler_id, raw_request, request_params)).to have_attributes(:isIncomplete => false, :items => [])
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        it 'should call complete method on the Completion Provider' do
          expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:complete).with(Object,line_num,char_num,{:tasks_mode=>false}).and_return('something')
          subject.request_textdocument_completion(connection_handler_id, raw_request, request_params)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:complete).with(Object,line_num,char_num,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true
          subject.request_textdocument_completion(connection_handler_id, raw_request, request_params)
        end

        context 'and an error occurs during completion' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:complete).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)
            subject.request_textdocument_completion(connection_handler_id, raw_request, request_params)
          end

          it 'should reply with a complete, empty response' do
            expect(subject.request_textdocument_completion(connection_handler_id, raw_request, request_params)).to have_attributes(:isIncomplete => false, :items => [])
          end
        end
      end
    end

    # completionItem/resolve - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#completion-item-resolve-request-leftwards_arrow_with_hook
    describe '.request_completionitem_resolve' do
      let(:request_rpc_method) { 'completionItem/resolve' }
      let(:request_params) {{
        'type' => 'keyword',
        'name' => 'class',
        'data' => '',
      }}

      it 'should call resolve method on the Completion Provider' do
        expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:resolve).and_return('something')
        subject.request_completionitem_resolve(connection_handler_id, raw_request, request_params)
      end

      context 'and an error occurs during resolution' do
        before(:each) do
          expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:resolve).and_raise('MockError')
        end

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)
          subject.request_completionitem_resolve(connection_handler_id, raw_request, request_params)
        end

        it 'should reply with the same input params' do
          expect(subject.request_completionitem_resolve(connection_handler_id, raw_request, request_params)).to eq(request_params)
        end
      end
    end

    # textDocument/hover - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#hover-request-leftwards_arrow_with_hook
    describe '.request_textdocument_hover' do
      let(:request_rpc_method) { 'textDocument/hover' }
      let(:line_num) { 1 }
      let(:char_num) { 2 }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => line_num,
          'character' => char_num,
        },
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide hover/)
          subject.request_textdocument_hover(connection_handler_id, raw_request, request_params)
        end

        it 'should reply with nil for the contents' do
          expect(subject.request_textdocument_hover(connection_handler_id, raw_request, request_params)).to have_attributes(:contents => nil)
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        it 'should call resolve method on the Hover Provider' do
          expect(PuppetLanguageServer::Manifest::HoverProvider).to receive(:resolve).with(Object,line_num,char_num,{:tasks_mode=>false}).and_return('something')
          subject.request_textdocument_hover(connection_handler_id, raw_request, request_params)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::HoverProvider).to receive(:resolve).with(Object,line_num,char_num,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true
          subject.request_textdocument_hover(connection_handler_id, raw_request, request_params)
        end

        context 'and an error occurs during resolution' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::HoverProvider).to receive(:resolve).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)
            subject.request_textdocument_hover(connection_handler_id, raw_request, request_params)
          end

          it 'should reply with nil for the contents' do
            expect(subject.request_textdocument_hover(connection_handler_id, raw_request, request_params)).to have_attributes(:contents => nil)
          end
        end
      end
    end

    # textDocument/definition - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#goto-definition-request-leftwards_arrow_with_hook
    describe '.request_textdocument_definition' do
      let(:request_rpc_method) { 'textDocument/definition' }
      let(:line_num) { 1 }
      let(:char_num) { 2 }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => line_num,
          'character' => char_num,
        },
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide definition/)
          subject.request_textdocument_definition(connection_handler_id, raw_request, request_params)
        end

        it 'should reply with nil' do
          expect(subject.request_textdocument_definition(connection_handler_id, raw_request, request_params)).to be_nil
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        it 'should call find_definition method on the Definition Provider' do
          expect(PuppetLanguageServer::Manifest::DefinitionProvider).to receive(:find_definition)
            .with(Object,line_num,char_num,{:tasks_mode=>false}).and_return('something')
          subject.request_textdocument_definition(connection_handler_id, raw_request, request_params)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::DefinitionProvider).to receive(:find_definition)
            .with(Object,line_num,char_num,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true
          subject.request_textdocument_definition(connection_handler_id, raw_request, request_params)
        end

        context 'and an error occurs during definition' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::DefinitionProvider).to receive(:find_definition).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)
            subject.request_textdocument_definition(connection_handler_id, raw_request, request_params)
          end

          it 'should reply with nil' do
            expect(subject.request_textdocument_definition(connection_handler_id, raw_request, request_params)).to be_nil
          end
        end
      end
    end

    # textDocument/documentSymbol - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#document-symbols-request-leftwards_arrow_with_hook
    describe '.request_textdocument_documentsymbol' do
      let(:request_rpc_method) { 'textDocument/documentSymbol' }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        }
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide definition/)
          subject.request_textdocument_documentsymbol(connection_handler_id, raw_request, request_params)
        end

        it 'should reply with nil' do
          expect(subject.request_textdocument_documentsymbol(connection_handler_id, raw_request, request_params)).to be_nil
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        it 'should call extract_document_symbols method on the Document Symbol Provider' do
          expect(PuppetLanguageServer::Manifest::DocumentSymbolProvider).to receive(:extract_document_symbols)
            .with(Object,{:tasks_mode=>false}).and_return('something')
          subject.request_textdocument_documentsymbol(connection_handler_id, raw_request, request_params)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::DocumentSymbolProvider).to receive(:extract_document_symbols)
            .with(Object,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true
          subject.request_textdocument_documentsymbol(connection_handler_id, raw_request, request_params)
        end

        context 'and an error occurs during extraction' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::DocumentSymbolProvider).to receive(:extract_document_symbols).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)
            subject.request_textdocument_documentsymbol(connection_handler_id, raw_request, request_params)
          end

          it 'should reply with nil' do
            expect(subject.request_textdocument_documentsymbol(connection_handler_id, raw_request, request_params)).to be_nil
          end
        end
      end
    end

    # textDocument/onTypeFormatting - https://microsoft.github.io/language-server-protocol/specification#textDocument_onTypeFormatting
    describe '.request_textdocument_ontypeformatting' do
      let(:request_rpc_method) { 'textDocument/onTypeFormatting' }
      let(:file_uri) { MANIFEST_FILENAME }
      let(:file_content) { "{\n  a =>\n  name => 'value'\n}\n" }
      let(:line_num) { 1 }
      let(:char_num) { 6 }
      let(:trigger_char) { '>' }
      let(:formatting_options) { { 'tabSize' => 2, 'insertSpaces' => true} }
      let(:request_params) { {
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => line_num,
          'character' => char_num,
        },
        'ch' => trigger_char,
        'options' => formatting_options
      } }
      let(:provider) { PuppetLanguageServer::Manifest::FormatOnTypeProvider.new }

      before(:each) do
        subject.documents.clear
        subject.documents.set_document(file_uri,file_content, 0)
      end

      context 'with client.format_on_type set to false' do
        before(:each) do
          allow(subject.language_client).to receive(:format_on_type).and_return(false)
        end

        it 'should reply with nil' do
          expect(subject.request_textdocument_ontypeformatting(connection_handler_id, raw_request, request_params)).to be_nil
        end
      end

      context 'with client.format_on_type set to true' do
        before(:each) do
          allow(subject.language_client).to receive(:format_on_type).and_return(true)
        end

        context 'for a file the server does not understand' do
          let(:file_uri) { UNKNOWN_FILENAME }

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to format on type on/)
            subject.request_textdocument_ontypeformatting(connection_handler_id, raw_request, request_params)
          end

          it 'should reply with nil' do
            expect(subject.request_textdocument_ontypeformatting(connection_handler_id, raw_request, request_params)).to be_nil
          end
        end

        context 'for a puppet manifest file' do
          let(:file_uri) { MANIFEST_FILENAME }

          before(:each) do
            allow(PuppetLanguageServer::Manifest::FormatOnTypeProvider).to receive(:instance).and_return(provider)
          end

          it 'should call format method on the Format On Type provider' do
            expect(provider).to receive(:format)
              .with(file_content, line_num, char_num, trigger_char, formatting_options).and_return('something')
            subject.request_textdocument_ontypeformatting(connection_handler_id, raw_request, request_params)
          end

          context 'and an error occurs during formatting' do
            before(:each) do
              expect(provider).to receive(:format).and_raise('MockError')
            end

            it 'should log an error message' do
              expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)
              subject.request_textdocument_ontypeformatting(connection_handler_id, raw_request, request_params)
            end

            it 'should reply with nil' do
              expect(subject.request_textdocument_ontypeformatting(connection_handler_id, raw_request, request_params)).to be_nil
            end
          end
        end
      end
    end

  #   context 'given an unknown request' do
  #     let(:request_rpc_method) { 'unknown_request_method' }

  #     it 'should log an error message' do
  #       expect(PuppetLanguageServer).to receive(:log_message).with(:error,"Unknown RPC method #{request_rpc_method}")

  #       subject.receive_request(request)
  #     end
  #   end
  end

  # describe '#receive_notification' do
  #   let(:notification_method) { nil }
  #   let(:notification_params) { {} }

  #   context 'given a notification that raises an error' do
  #     let(:notification_method) { 'exit' }
  #     before(:each) do
  #       expect(subject.json_rpc_handler).to receive(:close_connection).and_raise('MockError')
  #       allow(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
  #     end

  #     it 'should raise an error' do
  #       expect{ subject.receive_notification(notification_method, notification_params) }.to raise_error(/MockError/)
  #     end

  #     it 'should call PuppetLanguageServer::CrashDump.write_crash_file' do
  #       expect(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
  #       expect{ subject.receive_notification(notification_method, notification_params) }.to raise_error(/MockError/)
  #     end
  #   end

  #   context 'given a notification that is protocol implementation dependant' do
  #     let(:notification_method) { '$/MockNotification' }

  #     it 'should log a debug message' do
  #       expect(PuppetLanguageServer).to receive(:log_message).with(:debug, /Ignoring .+ #{Regexp.escape(notification_method)}/)
  #       subject.receive_notification(notification_method, notification_params)
  #     end
  #   end

  #   # initialized - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#initialized
  #   context 'given an initialized notification' do
  #     let(:notification_method) { 'initialized' }

  #     it 'should log a message' do
  #       expect(PuppetLanguageServer).to receive(:log_message).with(:info, /initialization/)
  #       allow(PuppetLanguageServer).to receive(:log_message).with(:debug, String)

  #       subject.receive_notification(notification_method, notification_params)
  #     end

  #     context 'when the client supports dynamic registration of workspace/didChangeConfiguration' do
  #       before(:each) do
  #         allow(subject.client).to receive(:client_capability).with('workspace', 'didChangeConfiguration', 'dynamicRegistration').and_return(true)
  #       end

  #       it 'should attempt to register workspace/didChangeConfiguration' do
  #         expect(subject.client).to receive(:register_capability).with('workspace/didChangeConfiguration')

  #         subject.receive_notification(notification_method, notification_params)
  #       end
  #     end

  #     context 'when the client does not support dynamic registration of workspace/didChangeConfiguration' do
  #       before(:each) do
  #         allow(subject.client).to receive(:client_capability).with('workspace', 'didChangeConfiguration', 'dynamicRegistration').and_return(nil)
  #       end

  #       it 'should log a debug message' do
  #         expect(PuppetLanguageServer).to receive(:log_message).with(:debug, /Client does not support didChangeConfiguration/)
  #         expect(PuppetLanguageServer).to receive(:log_message).with(Symbol, String)

  #         subject.receive_notification(notification_method, notification_params)
  #       end
  #     end
  #   end

  #   # exit - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#exit-notification
  #   context 'given an exit notification' do
  #     let(:notification_method) { 'exit' }

  #     before(:each) do
  #       allow(subject).to receive(:close_connection)
  #     end

  #     it 'should log a message' do
  #       expect(PuppetLanguageServer).to receive(:log_message).with(:info,String)

  #       subject.receive_notification(notification_method, notification_params)
  #     end

  #     it 'should close the connection' do
  #       expect(subject.json_rpc_handler).to receive(:close_connection)

  #       subject.receive_notification(notification_method, notification_params)
  #     end
  #   end

  #   # textDocument/didOpen - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#textDocument_didOpen
  #   context 'given a textDocument/didOpen notification' do
  #     shared_examples_for "an opened document with enqueued validation" do |file_uri, file_content|
  #       let(:notification_method) { 'textDocument/didOpen' }
  #       let(:notification_params) { {
  #         'textDocument' => {
  #           'uri' => file_uri,
  #           'languageId' => 'puppet',
  #           'version' => 1,
  #           'text' => file_content,
  #         }
  #       }}

  #       it 'should add the document to the document store' do
  #         subject.receive_notification(notification_method, notification_params)
  #         expect(subject.documents.document(file_uri)).to eq(file_content)
  #       end

  #       it 'should enqueue the file for validation' do
  #         expect(PuppetLanguageServer::ValidationQueue).to receive(:enqueue).with(file_uri, 1, Object)
  #         subject.receive_notification(notification_method, notification_params)
  #       end
  #     end

  #     before(:each) do
  #       subject.documents.clear
  #     end

  #     context 'for a puppet manifest file' do
  #       it_should_behave_like "an opened document with enqueued validation", MANIFEST_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end

  #     context 'for a Puppetfile file' do
  #       it_should_behave_like "an opened document with enqueued validation", PUPPETFILE_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end

  #     context 'for an EPP template file' do
  #       it_should_behave_like "an opened document with enqueued validation", EPP_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end

  #     context 'for an unknown file' do
  #       it_should_behave_like "an opened document with enqueued validation", UNKNOWN_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end
  #   end

  #   # textDocument/didClose - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#didclosetextdocument-notification
  #   context 'given a textDocument/didClose notification' do
  #     let(:notification_method) { 'textDocument/didClose' }
  #     let(:notification_params) { {
  #       'textDocument' => { 'uri' => file_uri}
  #     }}
  #     let(:file_uri) { MANIFEST_FILENAME }
  #     let(:file_content) { 'file_content' }

  #     before(:each) do
  #       subject.documents.clear
  #       subject.documents.set_document(file_uri,file_content, 0)
  #     end

  #     it 'should remove the document from the document store' do
  #       subject.receive_notification(notification_method, notification_params)
  #       expect(subject.documents.document(file_uri)).to be_nil
  #     end
  #   end

  #   # textDocument/didChange - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#didchangetextdocument-notification
  #   context 'given a textDocument/didChange notification and a TextDocumentSyncKind of Full' do
  #     shared_examples_for "a changed document with enqueued validation" do |file_uri, new_file_content|
  #       let(:notification_params) { {
  #         'textDocument' => {
  #           'uri' => file_uri,
  #           'version' => 2,
  #         },
  #         'contentChanges' => [
  #           {
  #             'range' => nil,
  #             'rangeLength' => nil,
  #             'text' => new_file_content,
  #           }
  #         ]
  #       }}
  #       let(:notification_method) { 'textDocument/didChange' }
  #       let(:new_file_content ) { 'new_file_content' }

  #       it 'should update the document in the document store' do
  #         subject.receive_notification(notification_method, notification_params)
  #         expect(subject.documents.document(file_uri)).to eq(new_file_content)
  #       end

  #       it 'should enqueue the file for validation' do
  #         expect(PuppetLanguageServer::ValidationQueue).to receive(:enqueue).with(file_uri, 2, Object)
  #         subject.receive_notification(notification_method, notification_params)
  #       end
  #     end

  #     before(:each) do
  #       subject.documents.clear
  #     end

  #     context 'for a puppet manifest file' do
  #       it_should_behave_like "a changed document with enqueued validation", MANIFEST_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end

  #     context 'for a Puppetfile file' do
  #       it_should_behave_like "a changed document with enqueued validation", PUPPETFILE_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end

  #     context 'for an EPP template file' do
  #       it_should_behave_like "a changed document with enqueued validation", EPP_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end

  #     context 'for a file the server does not understand' do
  #       it_should_behave_like "a changed document with enqueued validation", UNKNOWN_FILENAME, ERROR_CAUSING_FILE_CONTENT
  #     end
  #   end

  #   # textDocument/didSave - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#didsavetextdocument-notification
  #   context 'given a textDocument/didSave notification' do
  #     let(:notification_method) { 'textDocument/didSave' }
  #     it 'should log a message' do
  #       expect(PuppetLanguageServer).to receive(:log_message).with(:info,String)

  #       subject.receive_notification(notification_method, notification_params)
  #     end
  #   end

  #   # workspace/didChangeConfiguration - https://microsoft.github.io/language-server-protocol/specification#workspace_didChangeConfiguration
  #   context 'given a workspace/didChangeConfiguration notification' do
  #     let(:notification_method) { 'workspace/didChangeConfiguration' }
  #     let(:notification_params) { {
  #       'settings' => config_settings
  #     }}

  #     # Server Pull method for settings
  #     context 'given a settings with value of nil' do
  #       let(:config_settings) { nil }

  #       it 'should send a configuration request' do
  #         expect(subject.client).to receive(:send_configuration_request).with(no_args)

  #         subject.receive_notification(notification_method, notification_params)
  #       end
  #     end

  #     # Legacy Client Push method for settings
  #     context 'given a settings with value of non-empty Hash' do
  #       let(:config_settings) { { 'setting1' => 'value1' } }

  #       it 'should parse the settings' do
  #         expect(subject.client).to receive(:parse_lsp_configuration_settings!).with(config_settings)

  #         subject.receive_notification(notification_method, notification_params)
  #       end
  #     end
  #   end

  #   context 'given an unknown notification' do
  #     let(:notification_method) { 'unknown_notification_method' }

  #     it 'should log an error message' do
  #       expect(PuppetLanguageServer).to receive(:log_message).with(:error,"Unknown RPC notification #{notification_method}")

  #       subject.receive_notification(notification_method, notification_params)
  #     end
  #   end
  # end

  # describe '#receive_response' do
  #   let(:request_id) { 0 }
  #   let(:response_result) { nil }
  #   let(:response) { {'jsonrpc'=>'2.0', 'id'=> request_id, 'result' => response_result } }
  #   let(:original_request) { {'jsonrpc'=>'2.0', 'id'=> request_id, 'method' => request_method, 'params' => request_params} }

  #   before(:each) do
  #     allow(PuppetLanguageServer).to receive(:log_message)
  #   end

  #   context 'given a response that errored' do
  #     let(:request_method) { 'mockMethod'}
  #     let(:request_params) { {} }

  #     before(:each) do
  #       response.delete('result') if response.key?('result')
  #       response['error'] = { 'code' => -1, 'message' => 'mock message' }
  #     end

  #     it 'should log the error' do
  #       expect(PuppetLanguageServer).to receive(:log_message).with(:error, /.+#{request_method}.+#{request_id}.+mock message.+/)

  #       subject.receive_response(response, original_request)
  #     end
  #   end

  #   context 'given an error during processing' do
  #     let(:request_method) { 'client/registerCapability'}
  #     let(:request_params) { {} }

  #     before(:each) do
  #       expect(subject.client).to receive(:parse_register_capability_response!).and_raise('MockError')
  #       allow(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
  #     end

  #     it 'should raise an error' do
  #       expect{ subject.receive_response(response, original_request) }.to raise_error(/MockError/)
  #     end

  #     it 'should call PuppetLanguageServer::CrashDump.write_crash_file' do
  #       expect(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
  #       expect{ subject.receive_response(response, original_request) }.to raise_error(/MockError/)
  #     end
  #   end

  #   context 'given an original client/registerCapability request' do
  #     let(:request_method) { 'client/registerCapability'}
  #     let(:request_params) { {} }

  #     it 'should call client.parse_register_capability_response!' do
  #       expect(subject.client).to receive(:parse_register_capability_response!).with(response, original_request)

  #       subject.receive_response(response, original_request)
  #     end
  #   end

  #   context 'given an original workspace/configuration request' do
  #     let(:response_result) { [{ 'setting1' => 'value1' }] }
  #     let(:request_method) { 'workspace/configuration'}
  #     let(:request_params) do
  #       params = LSP::ConfigurationParams.new.from_h!('items' => [])
  #       params.items << LSP::ConfigurationItem.new.from_h!('section' => 'mock')
  #       params
  #     end

  #     it 'should call client.parse_lsp_configuration_settings!' do
  #       expect(subject.client).to receive(:parse_lsp_configuration_settings!).with({ 'mock' => response_result[0] })

  #       subject.receive_response(response, original_request)
  #     end
  #   end
  # end
end
