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
            'required' => [],
            'additionalProperties' => false
          }
        }.freeze

        def initialize(http, base_url, headers: {})
          @http = http
          @base_url = base_url
          @headers = headers
        end

        def schema_for(resource_type)
          schemas = fetch_schemas(urns_for(resource_type))
          core = schemas[resource_type[:schema]]
          return nil if core.nil?

          compose(resource_type, schemas, core)
        end

        private

        attr_reader :http, :base_url, :headers

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
            'required' => required,
            'additionalProperties' => false
          }
        end

        def merge_extensions(resource_type, schemas, properties, required)
          Array(resource_type[:schemaExtensions]).each do |extension|
            extension_schema = schemas[extension[:schema]]
            next unless extension_schema

            properties[extension[:schema]] =
              ScimSchemaConverter.convert(extension_schema)
            required << extension[:schema] if extension[:required]
          end
        end

        def fetch_schemas(urns)
          uri = Cli.join_uri(base_url, 'Schemas')
          result = http.fetch(uri, headers: headers)
          return {} unless result.ok? && result.body.is_a?(Array)

          result.body.each_with_object({}) do |schema, hash|
            hash[schema[:id]] = schema if urns.include?(schema[:id])
          end
        end
      end
    end
  end
end
