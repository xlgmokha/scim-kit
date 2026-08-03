# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class ResourceSchemaResolver
        COMMON_PROPERTIES = {
          'schemas' => {
            'type' => 'array', 'items' => { 'type' => 'string' }
          },
          'id' => { 'type' => 'string' },
          'externalId' => { 'type' => 'string' },
          'meta' => {
            'type' => 'object',
            'properties' => {
              'resourceType' => { 'type' => 'string' },
              'created' => { 'type' => 'string', 'format' => 'date-time' },
              'lastModified' => {
                'type' => 'string', 'format' => 'date-time'
              },
              'location' => { 'type' => 'string' },
              'version' => { 'type' => 'string' }
            },
            'required' => ['resourceType']
          }
        }.freeze

        COMMON_REQUIRED = %w[schemas id].freeze

        attr_reader :undeclared_extensions

        def initialize(client)
          @client = client
          @undeclared_extensions = []
        end

        def schema_for(resource_type)
          schemas = fetch_schemas(urns_for(resource_type))
          core = schemas[resource_type[:schema]]
          return nil if core.nil?

          compose(resource_type, schemas, core)
        end

        private

        attr_reader :client

        def urns_for(resource_type)
          extensions = Array(resource_type[:schemaExtensions])
          [
            resource_type[:schema],
            *extensions.map { |e| e[:schema] }
          ].compact
        end

        def compose(resource_type, schemas, core)
          converted = ScimSchemaConverter.convert(core)
          properties = COMMON_PROPERTIES.merge(converted['properties'])
          required = converted['required']
          merge_extensions(
            resource_type, schemas, properties, required
          )
          build_schema(properties, required)
        end

        def build_schema(properties, required)
          {
            'type' => 'object',
            'properties' => properties,
            'required' => COMMON_REQUIRED | required
          }
        end

        def merge_extensions(resource_type, schemas, properties, required)
          Array(resource_type[:schemaExtensions]).each do |extension|
            extension_schema = schemas[extension[:schema]]
            unless extension_schema
              undeclared_extensions << extension[:schema]
              next
            end

            properties[extension[:schema]] =
              ScimSchemaConverter.convert(extension_schema)
            required << extension[:schema] if extension[:required]
          end
        end

        def fetch_schemas(urns)
          result = client.fetch('Schemas')
          schemas = result.ok? ? Cli.collection(result.body) : nil
          return {} if schemas.nil?

          schemas.each_with_object({}) do |schema, hash|
            hash[schema[:id]] = schema if urns.include?(schema[:id])
          end
        end
      end
    end
  end
end
