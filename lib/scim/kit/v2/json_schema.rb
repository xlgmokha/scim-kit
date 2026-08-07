# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # A JSON Schema, and the ways to obtain one. Every SCIM document this
      # gem validates is an entry point of the single bundled schema.json, so
      # "meta" and the ListResponse envelope are defined once there and
      # reached with $ref.
      class JsonSchema
        FILE = File.expand_path('schema.json', __dir__)
        RESOURCE_LIST = 'resourceList'

        ENTRY_POINTS = {
          service_provider_configuration: 'serviceProviderConfig',
          schemas: 'schemaList',
          resource_types: 'resourceTypeList',
          error: 'error'
        }.freeze

        class << self
          def fetch(key)
            entry_point(ENTRY_POINTS.fetch(key))
          end

          def definition(name)
            document.fetch('$defs').fetch(name)
          end

          # Selects any definition as the document to validate against, so a
          # fragment such as "meta" can be checked on its own.
          def entry_point(name, extra_definitions = {})
            schema = document
            schema['$defs'] = schema['$defs'].merge(extra_definitions)
            new(schema.merge('$ref' => "#/$defs/#{name}"))
          end

          # The resource schema is built from the target server's own
          # /Schemas, so it is added as one more definition rather than living
          # in the file.
          def list_of(resource_schema)
            entry_point(RESOURCE_LIST, RESOURCE_LIST => {
              'allOf' => [
                { '$ref' => '#/$defs/listResponse' },
                { 'properties' => {
                  'Resources' => { 'items' => resource_schema }
                } }
              ]
            })
          end

          private

          def document
            JSON.parse(source)
          end

          def source
            @source ||= File.read(FILE)
          end
        end

        def initialize(schema)
          @schema = schema
        end

        def errors_for(data)
          document = UnassignedValues.strip(normalize(data))
          JSONSchemer.schema(schema)
            .validate(CanonicalKeys.apply(schema, document))
            .map { |error| message_for(error) }
        end

        def to_h
          schema
        end

        private

        attr_reader :schema

        def message_for(error)
          return JSONSchemer::Errors.pretty(error) unless
            error['type'] == 'contains'

          "property '#{error['data_pointer']}' does not contain: " \
            "#{error['schema']['contains']['const'].inspect}"
        end

        def normalize(data)
          JSON.parse(JSON.generate(data))
        end
      end
    end
  end
end
