# frozen_string_literal: true

require 'lsp/lsp'

module PuppetLanguageServer
  module Puppetfile
    module InfoProvider
      def self.max_line_length
        # TODO: ... need to figure out the actual line length
        1000
      end

      def self.get_info(content)
        require 'puppetfile-resolver'
        resolver = PuppetfileResolver::Resolver.new(content, nil)

        # Configure the resolver
        cache                 = nil  # Use the default inmemory cache
        ui                    = nil  # Don't output any information
        module_paths          = []   # List of paths to search for modules on the local filesystem
        allow_missing_modules = true # Allow missing dependencies to be resolved
        opts = { cache: cache, ui: ui, module_paths: module_paths, allow_missing_modules: allow_missing_modules }

        # Resolve
        result = resolver.resolve(opts)
        require 'pry';binding.pry
        resolver.dependencies_to_resolve
      end
    end
  end
end
