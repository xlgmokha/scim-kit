# frozen_string_literal: true

require 'thor'

require 'scim/kit/cli/reporting'
require 'scim/kit/cli/resource_type_resolver'
require 'scim/kit/cli/scim_schema_converter'
require 'json_schemer'
require 'scim/kit/cli/schema_registry'
require 'scim/kit/cli/validator'
require 'scim/kit/cli/resource_schema_resolver'
require 'scim/kit/cli/app'

module Scim
  module Kit
    module Cli
      class Error < Scim::Kit::Error; end

      class RequestFailed < Error
        attr_reader :result

        def initialize(result)
          @result = result
          super("request failed with status #{result.status.inspect}")
        end
      end

      class UnknownResourceType < Error
        def initialize(name, known_names)
          super("unknown resource type #{name.inspect} (known: #{known_names.join(', ')})")
        end
      end

      class MissingEndpoint < Error
        def initialize(name)
          super("resource type #{name.inspect} has no endpoint")
        end
      end

      class InvalidResponse < Error; end

      def self.join_uri(base_url, path)
        URI.join("#{base_url.to_s.sub(%r{/+\z}, '')}/", path)
      end
    end
  end
end
