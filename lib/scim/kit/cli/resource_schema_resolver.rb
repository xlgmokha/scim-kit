# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class ResourceSchemaResolver
        # RFC 7232 2.3: entity-tag = [ "W/" ] DQUOTE *etagc DQUOTE, where
        # etagc is a visible character other than a double quote. obs-text is
        # left out, being obsolete.
        ENTITY_TAG = '^(W/)?"[!#-~]*"$'

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
              'version' => { 'type' => 'string', 'pattern' => ENTITY_TAG }
            }
          }
        }.freeze

        COMMON_REQUIRED = %w[schemas id].freeze

        # RFC 7643 6 makes "id" OPTIONAL for these discovery resources.
        OPTIONAL_ID_SCHEMAS = [
          'urn:ietf:params:scim:schemas:core:2.0:ResourceType',
          'urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'
        ].freeze

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
          # RFC 7643 3.1 gives the common attributes precedence over any
          # definition a server repeats in its own schema.
          properties['schemas'] = schemas_property(resource_type)
          required = converted['required']
          merge_extensions(
            resource_type, schemas, properties, required
          )
          build_schema(properties, common_required(resource_type) | required)
        end

        # RFC 7643 3.1: a non-empty array naming the URIs of the schemas the
        # representation supports, so the resource type's own schema is one.
        def schemas_property(resource_type)
          COMMON_PROPERTIES['schemas'].merge(
            'contains' => { 'const' => resource_type[:schema] }
          )
        end

        def build_schema(properties, required)
          {
            'type' => 'object',
            'properties' => properties,
            'required' => required
          }
        end

        def common_required(resource_type)
          return COMMON_REQUIRED unless
            OPTIONAL_ID_SCHEMAS.include?(resource_type[:schema])

          COMMON_REQUIRED - ['id']
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
