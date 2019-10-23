# frozen_string_literal: true

# Custom LSP Messages

module LSP
  # export interface PuppetVersionDetails {
  #   puppetVersion: string;
  #   facterVersion: string;
  #   languageServerVersion: string;
  #   factsLoaded: boolean;
  #   functionsLoaded: boolean;
  #   typesLoaded: boolean;
  #   classesLoaded: boolean;
  # }
  class PuppetVersion < LSPBase
    attr_accessor :puppetVersion # type: string
    attr_accessor :facterVersion # type: string
    attr_accessor :languageServerVersion # type: string
    attr_accessor :factsLoaded # type: boolean
    attr_accessor :functionsLoaded # type: boolean
    attr_accessor :typesLoaded # type: boolean
    attr_accessor :classesLoaded # type: boolean

    def from_h!(value)
      value = {} if value.nil?
      self.puppetVersion = value['puppetVersion']
      self.facterVersion = value['facterVersion']
      self.languageServerVersion = value['languageServerVersion']
      self.factsLoaded = value['factsLoaded']
      self.functionsLoaded = value['functionsLoaded']
      self.typesLoaded = value['typesLoaded']
      self.classesLoaded = value['classesLoaded']
      self
    end
  end

  # export interface GetPuppetResourceResponse {
  #   data: string;
  #   error: string;
  # }
  class PuppetResourceResponse < LSPBase
    attr_accessor :data # type: string
    attr_accessor :error # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[error]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.data = value['data']
      self.error = value['error']
      self
    end
  end

  # export interface CompileNodeGraphResponse {
  #   dotContent: string;
  #   data: string;
  # }
  class CompileNodeGraphResponse < LSPBase
    attr_accessor :dotContent # type: string
    attr_accessor :error # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[error]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dotContent = value['dotContent']
      self.error = value['error']
      self
    end
  end

  # export interface PuppetFixDiagnosticErrorsRequestParams {
  #   documentUri: string;
  #   alwaysReturnContent: boolean;
  # }
  class PuppetFixDiagnosticErrorsRequest < LSPBase
    attr_accessor :documentUri # type: string
    attr_accessor :alwaysReturnContent # type: boolean

    def from_h!(value)
      value = {} if value.nil?
      self.documentUri = value['documentUri']
      self.alwaysReturnContent = value['alwaysReturnContent']
      self
    end
  end

  # export interface PuppetFixDiagnosticErrorsResponse {
  #   documentUri: string;
  #   fixesApplied: number;
  #   newContent?: string;
  # }
  class PuppetFixDiagnosticErrorsResponse < LSPBase
    attr_accessor :documentUri # type: string
    attr_accessor :fixesApplied # type: number
    attr_accessor :newContent # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[newContent]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentUri = value['documentUri']
      self.fixesApplied = value['fixesApplied']
      self.newContent = value['newContent']
      self
    end
  end

  class Message < LSPBase
    attr_accessor :jsonrpc # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.jsonrpc = value['jsonrpc']
      self
    end
  end

  class RequestMessage < Message
    attr_accessor :id
    attr_accessor :method
    attr_accessor :params

    def from_h!(value)
      value = {} if value.nil?
      self.id     = value['id']
      self.method = value['method']
      self.params = value['params']
      self
    end
  end

  class InitializeRequest < RequestMessage
    attr_accessor :processId #: number | null;
    attr_accessor :rootPath #?: string | null;
    attr_accessor :rootUri #: DocumentUri | null;
    attr_accessor :initializationOptions #?: any;
    attr_accessor :capabilities #: ClientCapabilities;
    attr_accessor :trace #?: 'off' | 'messages' | 'verbose';
    attr_accessor :workspaceFolders #?: WorkspaceFolder[] | null;

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[
        rootPath,
        initializationOptions,
        workspaceFolders
      ]
    end

    def from_h!(value)
      value                      = {} if value.nil?
      self.processId             = value['processId']
      self.rootPath              = value['rootPath']
      self.rootUri               = value['rootUri']
      self.initializationOptions = value['initializationOptions']
      self.capabilities          = ClientCapabilities.new(value['capabilities'])
      self.trace                 = value['trace']
      self.workspaceFolders      = value['workspaceFolders']
      self
    end
  end

  class ClientCapabilities < LSPBase
    attr_accessor :workspace #?: WorkspaceClientCapabilities;
    attr_accessor :textDocument #?: TextDocumentClientCapabilities;
    attr_accessor :experimental #?: any;

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[
        workspace,
        textDocument,
        experimental
      ]
    end

    def from_h!(value)
      value             = {} if value.nil?
      self.workspace    = WorkspaceClientCapabilities.new(value['workspace'])
      self.textDocument = TextDocumentClientCapabilities.new(value['textDocument'])
      self.experimental = value['experimental']
      self
    end
  end

  class WorkspaceClientCapabilities < LSPBase
    attr_accessor :applyEdit              # boolean
    attr_accessor :workspaceEdit          # {}
    attr_accessor :didChangeConfiguration # {}
    attr_accessor :didChangeWatchedFiles  # {}
    attr_accessor :symbol                 # {}
    attr_accessor :executeCommand         # {}
    attr_accessor :workspaceFolders       # boolean
    attr_accessor :configuration          # boolean

    def from_h!(value)
      value                       = {} if value.nil?
      self.applyEdit              = value['applyEdit']
      self.workspaceEdit          = value['workspaceEdit']
      self.didChangeConfiguration = value['didChangeConfiguration']
      self.didChangeWatchedFiles  = value['didChangeWatchedFiles']
      self.symbol                 = value['symbol']
      self.executeCommand         = value['executeCommand']
      self.workspaceFolders       = value['workspaceFolders']
      self.configuration          = value['configuration']
      self
    end
  end

  class TextDocumentClientCapabilities < LSPBase
    attr_accessor :synchronization
    attr_accessor :completion
    attr_accessor :hover
    attr_accessor :signatureHelp
    attr_accessor :references
    attr_accessor :documentHighlight
    attr_accessor :documentSymbol
    attr_accessor :formatting
    attr_accessor :rangeFormatting
    attr_accessor :onTypeFormatting
    attr_accessor :declaration
    attr_accessor :definition
    attr_accessor :typeDefinition
    attr_accessor :implementation
    attr_accessor :codeAction
    attr_accessor :codeLens
    attr_accessor :documentLink
    attr_accessor :colorProvider
    attr_accessor :rename
    attr_accessor :publishDiagnostics
    attr_accessor :foldingRange

    def from_h!(value)
      value                   = {} if value.nil?
      self.synchronization    = value['synchronization']
      self.completion         = value['completion']
      self.hover              = value['hover']
      self.signatureHelp      = value['signatureHelp']
      self.references         = value['references']
      self.documentHighlight  = value['documentHighlight']
      self.documentSymbol     = value['documentSymbol']
      self.formatting         = value['formatting']
      self.rangeFormatting    = value['rangeFormatting']
      self.onTypeFormatting   = value['onTypeFormatting']
      self.declaration        = value['declaration']
      self.definition         = value['definition']
      self.typeDefinition     = value['typeDefinition']
      self.implementation     = value['implementation']
      self.codeAction         = value['codeAction']
      self.codeLens           = value['codeLens']
      self.documentLink       = value['documentLink']
      self.colorProvider      = value['colorProvider']
      self.rename             = value['rename']
      self.publishDiagnostics = value['publishDiagnostics']
      self.foldingRange       = value['foldingRange']
    end
  end
end
