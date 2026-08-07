# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # The JSON Schema for a resource of one resource type: the RFC 7643 3.1
      # common attributes, its base schema's attributes, and each declared
      # extension namespaced under its URN (3.3).
      class ResourceSchema
        SCHEMAS = { 'type' => 'array', 'items' => { 'type' => 'string' } }.freeze
        COMMON_REQUIRED = %w[schemas id].freeze

        # RFC 7643 6 makes "id" OPTIONAL for these discovery resources.
        OPTIONAL_ID = [
          Schemas::RESOURCE_TYPE,
          Schemas::SERVICE_PROVIDER_CONFIGURATION
        ].freeze

        def initialize(resource_type, schemas, core)
          @resource_type = resource_type
          @schemas = schemas
          @core = core
        end

        def to_h
          converted = core.to_json_schema
          properties = common_properties.merge(converted['properties'])
          # RFC 7643 3.1 gives the common attributes precedence over any
          # definition a server repeats in its own schema.
          properties['schemas'] = schemas_property
          required = converted['required']
          merge_extensions(properties, required)
          {
            'type' => 'object',
            'properties' => properties,
            'required' => common_required | required
          }
        end

        private

        attr_reader :resource_type, :schemas, :core

        def common_properties
          {
            'schemas' => SCHEMAS,
            'id' => { 'type' => 'string' },
            'externalId' => { 'type' => 'string' },
            'meta' => JsonSchema.definition('meta')
          }
        end

        def schemas_property
          SCHEMAS.merge('contains' => { 'const' => resource_type.schema })
        end

        def common_required
          unless OPTIONAL_ID.include?(resource_type.schema)
            return COMMON_REQUIRED
          end

          COMMON_REQUIRED - ['id']
        end

        def merge_extensions(properties, required)
          resource_type.schema_extensions.each do |extension|
            urn = extension[:schema]
            required << urn if extension[:required]
            schema = schemas[urn]
            next unless schema

            properties[urn] = schema.to_json_schema
          end
        end
      end
    end
  end
end
