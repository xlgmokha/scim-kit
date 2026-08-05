# frozen_string_literal: true

require 'json_schemer'
require 'thor'

require 'scim/kit/cli/app'
require 'scim/kit/cli/canonical_keys'
require 'scim/kit/cli/client'
require 'scim/kit/cli/discovery'
require 'scim/kit/cli/reporter'
require 'scim/kit/cli/resource_schema_resolver'
require 'scim/kit/cli/resource_type_resolver'
require 'scim/kit/cli/resource_validation'
require 'scim/kit/cli/schema_registry'
require 'scim/kit/cli/scim_schema_converter'
require 'scim/kit/cli/settings'
require 'scim/kit/cli/sparse_schema'
require 'scim/kit/cli/unassigned_values'
require 'scim/kit/cli/validator'

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

      class InvalidOption < Error; end

      # RFC 7643 section 6 defines a resource type endpoint as relative to the
      # base URL. A server that advertises an absolute one on another origin
      # would otherwise be handed the credentials meant for the base URL.
      class OffOrigin < Error
        def initialize(uri, base_url)
          super(
            "refusing to send a request for #{base_url} to #{uri}, " \
            'which is a different origin'
          )
        end
      end

      # SCIM collection endpoints (/Schemas, /ResourceTypes) return a
      # ListResponse per RFC 7644 section 4, but some servers return a
      # bare array. Return the underlying array for either shape, or nil.
      def self.collection(body)
        return body if body.is_a?(Array)
        return unless body.is_a?(Hash)

        resources = body[:Resources]
        resources if resources.is_a?(Array)
      end
    end
  end
end
