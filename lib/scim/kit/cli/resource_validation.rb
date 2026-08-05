# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class ResourceValidation
        def initialize(resolver, reporter)
          @resolver = resolver
          @reporter = reporter
        end

        def errors_for(entry, body, sparse: false, &transform)
          schema = schema_for(entry)
          return unless schema

          Validator.errors_for(prepare(schema, sparse, &transform), body)
        end

        private

        attr_reader :resolver, :reporter

        def schema_for(entry)
          schema = resolver.schema_for(entry)
          schema ? warn_undeclared_extensions : warn_unresolvable_schema(entry)
          schema
        end

        def prepare(schema, sparse)
          schema = SparseSchema.relax(schema) if sparse
          block_given? ? yield(schema) : schema
        end

        def warn_unresolvable_schema(entry)
          reporter.warn(
            "no schema found for resource type #{entry[:name].inspect}; " \
            'cannot validate the response'
          )
        end

        def warn_undeclared_extensions
          resolver.undeclared_extensions.each do |urn|
            reporter.warn(
              "schema extension #{urn.inspect} is declared by the resource " \
              'type but missing from /Schemas'
            )
          end
        end
      end
    end
  end
end
