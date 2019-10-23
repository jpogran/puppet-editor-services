# frozen_string_literal: true

require 'puppet_editor_services/handler/json_rpc'

module PuppetLanguageServer
  class MessageHandler < PuppetEditorServices::Handler::JsonRPC
    attr_reader :language_client

    def initialize(*_)
      super
      @language_client = LanguageClient.new(self)
    end

    # TODO: Calls to this should be refactored to client_handler
    # @deprecated
    def json_rpc_handler
      client_handler
    end

    def documents
      PuppetLanguageServer::DocumentStore
    end

    def request_initialize(_, _raw_request, params)
      PuppetLanguageServer.log_message(:debug, 'Received initialize method')

      request = LSP::InitializeRequest.new(params)

      language_client.parse_lsp_initialize!(params)
      # Setup static registrations if dynamic registration is not available
      info = {
        :documentOnTypeFormattingProvider => !request.capabilities.textDocument.onTypeFormatting['dynamicRegistration']
      }

      { 'capabilities' => PuppetLanguageServer::ServerCapabilites.capabilities(info) }
    end

    def request_shutdown(_, _raw_request, _params)
      PuppetLanguageServer.log_message(:debug, 'Received shutdown method')
      nil
    end

    def request_puppet_getversion(_, _raw_request, _params)
      LSP::PuppetVersion.new(
        'languageServerVersion' => PuppetEditorServices.version,
        'puppetVersion'         => Puppet.version,
        'facterVersion'         => Facter.version,
        'factsLoaded'           => PuppetLanguageServer::FacterHelper.facts_loaded?,
        'functionsLoaded'       => PuppetLanguageServer::PuppetHelper.default_functions_loaded?,
        'typesLoaded'           => PuppetLanguageServer::PuppetHelper.default_types_loaded?,
        'classesLoaded'         => PuppetLanguageServer::PuppetHelper.default_classes_loaded?
      )
    end

    def request_puppet_getresource(_, _raw_request, params)
      type_name = params['typename']
      title = params['title']
      return LSP::PuppetResourceResponse.new('error' => 'Missing Typename') if type_name.nil?

      resource_list = PuppetLanguageServer::PuppetHelper.get_puppet_resource(type_name, title, documents.store_root_path)
      return LSP::PuppetResourceResponse.new('data' => '') if resource_list.nil? || resource_list.length.zero?

      content = resource_list.map(&:manifest).join("\n\n") + "\n"
      LSP::PuppetResourceResponse.new('data' => content)
    end

    def request_puppet_compilenodegraph(_, _raw_request, params)
      file_uri = params['external']
      return LSP::CompileNodeGraphResponse.new('error' => 'Files of this type can not be used to create a node graph.') unless documents.document_type(file_uri) == :manifest
      content = documents.document(file_uri)

      begin
        node_graph = PuppetLanguageServer::PuppetHelper.get_node_graph(content, documents.store_root_path)
        return LSP::CompileNodeGraphResponse.new('dotContent' => node_graph.dot_content,
                                                 'error'      => node_graph.error_content)
      rescue StandardError => e
        PuppetLanguageServer.log_message(:error, "(puppet/compileNodeGraph) Error generating node graph. #{e}")
        return LSP::CompileNodeGraphResponse.new('error' => 'An internal error occured while generating the the node graph. Please see the debug log files for more information.')
      end
    end

    def request_puppet_fixdiagnosticerrors(_, _raw_request, params)
      formatted_request = LSP::PuppetFixDiagnosticErrorsRequest.new(params)
      file_uri = formatted_request.documentUri
      content = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        changes, new_content = PuppetLanguageServer::Manifest::ValidationProvider.fix_validate_errors(content)
      else
        raise "Unable to fixDiagnosticErrors on #{file_uri}"
      end

      LSP::PuppetFixDiagnosticErrorsResponse.new(
        'documentUri'  => formatted_request.documentUri,
        'fixesApplied' => changes,
        'newContent'   => changes > 0 || formatted_request.alwaysReturnContent ? new_content : nil
      )
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(puppet/fixDiagnosticErrors) #{e}")
      unless formatted_request.nil?
        return LSP::PuppetFixDiagnosticErrorsResponse.new(
          'documentUri'  => formatted_request.documentUri,
          'fixesApplied' => 0,
          'newContent'   => formatted_request.alwaysReturnContent ? content : nil # rubocop:disable Metrics/BlockNesting
        )
      end
    end

    def request_textdocument_completion(_, _raw_request, params)
      file_uri = params['textDocument']['uri']
      line_num = params['position']['line']
      char_num = params['position']['character']
      content = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        return PuppetLanguageServer::Manifest::CompletionProvider.complete(content, line_num, char_num, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri))
      else
        raise "Unable to provide completion on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/completion) #{e}")
      LSP::CompletionList.new('isIncomplete' => false, 'items' => [])
    end

    def request_completionitem_resolve(_, _raw_request, params)
      PuppetLanguageServer::Manifest::CompletionProvider.resolve(LSP::CompletionItem.new(params))
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(completionItem/resolve) #{e}")
      # Spit back the same params if an error happens
      params
    end

    def request_textdocument_hover(_, _raw_request, params)
      file_uri = params['textDocument']['uri']
      line_num = params['position']['line']
      char_num = params['position']['character']
      content = documents.document(file_uri)
      case documents.document_type(file_uri)
      when :manifest
        return PuppetLanguageServer::Manifest::HoverProvider.resolve(content, line_num, char_num, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri))
      else
        raise "Unable to provide hover on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/hover) #{e}")
      LSP::Hover.new
    end

    def request_textdocument_definition(_, _raw_request, params)
      file_uri = params['textDocument']['uri']
      line_num = params['position']['line']
      char_num = params['position']['character']
      content = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        return PuppetLanguageServer::Manifest::DefinitionProvider.find_definition(content, line_num, char_num, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri))
      else
        raise "Unable to provide definition on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/definition) #{e}")
      nil
    end

    def request_textdocument_documentsymbol(_, _raw_request, params)
      file_uri = params['textDocument']['uri']
      content  = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        return PuppetLanguageServer::Manifest::DocumentSymbolProvider.extract_document_symbols(content, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri))
      else
        raise "Unable to provide definition on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/documentSymbol) #{e}")
      nil
    end

    def request_textdocument_ontypeformatting(_, _raw_request, params)
      return nil unless language_client.format_on_type
      file_uri = params['textDocument']['uri']
      line_num = params['position']['line']
      char_num = params['position']['character']
      content  = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        return PuppetLanguageServer::Manifest::FormatOnTypeProvider.instance.format(
          content,
          line_num,
          char_num,
          params['ch'],
          params['options']
        )
      else
        raise "Unable to format on type on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/onTypeFormatting) #{e}")
      nil
    end

    def request_textdocument_signaturehelp(_, _raw_request, params)
      file_uri = params['textDocument']['uri']
      line_num = params['position']['line']
      char_num = params['position']['character']
      content  = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        return PuppetLanguageServer::Manifest::SignatureProvider.signature_help(
          content,
          line_num,
          char_num,
          :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri)
        )
      else
        raise "Unable to provide signatures on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/signatureHelp) #{e}")
      nil
    end

    def request_workspace_symbol(_, _raw_request, params)
      result = []
      result.concat(PuppetLanguageServer::Manifest::DocumentSymbolProvider.workspace_symbols(params['query'], PuppetLanguageServer::PuppetHelper.cache))
      result
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(workspace/symbol) #{e}")
      []
    end

    #    TODO: What about crash dumps?
    #     rescue StandardError => e
    #       PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'request' => request.rpc_method, 'params' => request.params)
    #       raise
    #     end

    def notification_initialized(_, _raw_request, _params)
      PuppetLanguageServer.log_message(:info, 'Client has received initialization')
      # Raise a warning if the Puppet version is mismatched
      unless handler_creation_options[:puppet_version].nil? || handler_creation_options[:puppet_version] == Puppet.version
        json_rpc_handler.send_show_message_notification(
          LSP::MessageType::WARNING,
          "Unable to use Puppet version '#{handler_creation_options[:puppet_version]}' as it is not available. Using version '#{Puppet.version}' instead."
        )
      end
      # Register for workspace setting changes if it's supported
      if language_client.client_capability('workspace', 'didChangeConfiguration', 'dynamicRegistration') == true
        language_client.register_capability('workspace/didChangeConfiguration')
      else
        PuppetLanguageServer.log_message(:debug, 'Client does not support didChangeConfiguration dynamic registration. Using push method for configuration change detection.')
      end
    end

    def notification_exit(_, _raw_request, _params)
      PuppetLanguageServer.log_message(:info, 'Received exit notification.  Closing connection to client...')
      json_rpc_handler.close_connection unless client_handler.nil?
    end

    def notification_textdocument_didopen(client_handler_id, _raw_request, params)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didOpen notification.')
      file_uri = params['textDocument']['uri']
      content = params['textDocument']['text']
      doc_version = params['textDocument']['version']
      documents.set_document(file_uri, content, doc_version)
      PuppetLanguageServer::ValidationQueue.enqueue(file_uri, doc_version, client_handler_id)
    end

    def notification_textdocument_didclose(_, _raw_request, params)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didClose notification.')
      file_uri = params['textDocument']['uri']
      documents.remove_document(file_uri)
    end

    def notification_textdocument_didchange(client_handler_id, _raw_request, params)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didChange notification.')
      file_uri = params['textDocument']['uri']
      content = params['contentChanges'][0]['text'] # TODO: Bad hardcoding zero
      doc_version = params['textDocument']['version']
      documents.set_document(file_uri, content, doc_version)
      PuppetLanguageServer::ValidationQueue.enqueue(file_uri, doc_version, client_handler_id)
    end

    def notification_textdocument_didsave(_, _raw_request, _params)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didSave notification.')
      # Expire the store cache so that the store information can re-evaluated
      PuppetLanguageServer::DocumentStore.expire_store_information
      if PuppetLanguageServer::DocumentStore.store_has_module_metadata? || PuppetLanguageServer::DocumentStore.store_has_environmentconf?
        # Load the workspace information
        PuppetLanguageServer::PuppetHelper.load_workspace_async
      else
        # Purge the workspace information
        PuppetLanguageServer::PuppetHelper.purge_workspace
      end
    end

    def notification_workspace_didchangeconfiguration(_, _raw_request, params)
      if params.key?('settings') && params['settings'].nil?
        # This is a notification from a dynamic registration. Need to send a workspace/configuration
        # request to get the actual configuration
        language_client.send_configuration_request
      else
        language_client.parse_lsp_configuration_settings!(params['settings'])
      end
    end

    #       else
    #         super
    #       end
    #     rescue StandardError => e
    #       PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'notification' => method, 'params' => params)
    #       raise
    #     end

    def response_client_registercapability(_, raw_response, original_request)
      language_client.parse_register_capability_response!(raw_response, original_request)
    end

    def response_client_unregistercapability(_, raw_response, original_request)
      language_client.parse_unregister_capability_response!(raw_response, original_request)
    end

    def response_workspace_configuration(_, raw_response, original_request)
      return unless ::PuppetEditorServices::JSONMessage.response_succesful?(raw_response)
      original_request['params'].items.each_with_index do |item, index|
        # The response from the client strips the section name so we need to re-add it
        language_client.parse_lsp_configuration_settings!(item.section => raw_response['result'][index])
      end
    end

    # TODO: What about crash-dumps?
    # rescue StandardError => e
    #   PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'response' => response, 'original_request' => original_request)
    #   raise
    # end

    #     private

    #     def receive_response_succesful?(response)
    #       response.key?('result')
    #     end
    #   end
  end
end

#   class DisabledMessageRouter < BaseMessageRouter
#     def receive_request(request)
#       case request.rpc_method
#       when 'initialize'
#         PuppetLanguageServer.log_message(:debug, 'Received initialize method')
#         # If the Language Server is not active then we can not respond to any capability. We also
#         # send a warning to the user telling them this
#         request.reply_result('capabilities' => PuppetLanguageServer::ServerCapabilites.no_capabilities)
#         # Add a minor delay before sending the notification to give the client some processing time
#         sleep(0.5)
#         json_rpc_handler.send_show_message_notification(
#           LSP::MessageType::WARNING,
#           'An error occured while the Language Server was starting. The server has been disabled.'
#         )

#       when 'shutdown'
#         PuppetLanguageServer.log_message(:debug, 'Received shutdown method')
#         request.reply_result(nil)

#       when 'puppet/getVersion'
#         # Clients may use the getVersion request to figure out when the server has "finished" loading. In this
#         # case just fake the response that we are fully loaded with unknown gem versions
#         request.reply_result(LSP::PuppetVersion.new(
#                                'puppetVersion'   => 'Unknown',
#                                'facterVersion'   => 'Unknown',
#                                'factsLoaded'     => true,
#                                'functionsLoaded' => true,
#                                'typesLoaded'     => true,
#                                'classesLoaded'   => true
#                              ))

#       else
#         # For any request return an internal error.
#         request.reply_internal_error('Puppet Language Server is not active')
#         PuppetLanguageServer.log_message(:error, "Unknown RPC method #{request.rpc_method}")
#       end
#     rescue StandardError => e
#       PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'request' => request.rpc_method, 'params' => request.params)
#       raise
#     end

#     def receive_notification(method, params)
#       case method
#       when 'initialized'
#         PuppetLanguageServer.log_message(:info, 'Client has received initialization')

#       when 'exit'
#         PuppetLanguageServer.log_message(:info, 'Received exit notification.  Closing connection to client...')
#         json_rpc_handler.close_connection

#       else
#         super
#       end
#     rescue StandardError => e
#       PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'notification' => method, 'params' => params)
#       raise
#     end
#   end
# end
