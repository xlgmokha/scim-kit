# frozen_string_literal: true

require 'thor'

require 'scim/kit/cli/app'
require 'scim/kit/cli/discovery'
require 'scim/kit/cli/reporter'
require 'scim/kit/cli/resource_schema_resolver'
require 'scim/kit/cli/resource_type_resolver'
require 'scim/kit/cli/resource_validation'
require 'scim/kit/cli/settings'

module Scim
  module Kit
    module Cli
      class Error < Scim::Kit::Error; end

      class InvalidOption < Error; end

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
