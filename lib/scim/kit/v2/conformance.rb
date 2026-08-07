# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # How far a server's responses conform to RFC 7643 and RFC 7644,
      # measured against what that server declares about itself.
      class Conformance
        def initialize(configuration = V2.configuration)
          @configuration = configuration
        end

        # Each discovery document against its own schema, then against each
        # other: a contradiction between them belongs to neither alone.
        def discovery_errors(body)
          errors = body.each_with_object({}) do |(key, document), acc|
            messages = JsonSchema.fetch(key).errors_for(document)
            acc[key] = messages unless messages.empty?
          end
          configuration.load(body)
          merge_undeclared_extensions(errors)
        end

        # Nil when the server never published the base schema, which is not
        # the same as a resource having nothing wrong with it.
        def resource_errors(body, resource_type:, list: false, sparse: false)
          json_schema_for(resource_type, list: list, sparse: sparse)
            &.errors_for(body)
        end

        def json_schema_for(resource_type, list: false, sparse: false)
          schema = resource_type.to_json_schema(schemas: configuration.schemas)
          return nil unless schema

          schema = SparseSchema.relax(schema) if sparse
          list ? JsonSchema.list_of(schema) : JsonSchema.new(schema)
        end

        private

        attr_reader :configuration

        def merge_undeclared_extensions(errors)
          messages = undeclared_extension_messages
          return errors if messages.empty?

          errors.merge(
            resource_types: errors.fetch(:resource_types, []) + messages
          )
        end

        def undeclared_extension_messages
          configuration.resource_types.values.flat_map do |type|
            type.undeclared_extensions(schemas: configuration.schemas)
              .map { |urn| undeclared_extension_message(type, urn) }
          end
        end

        def undeclared_extension_message(type, urn)
          "schema extension #{urn.inspect} is declared by resource type " \
            "#{type.name.inspect} but missing from /Schemas"
        end
      end
    end
  end
end
