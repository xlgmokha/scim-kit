# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      module ScimSchemaConverter
        TYPE_MAP = {
          'string' => { 'type' => 'string' },
          'reference' => { 'type' => 'string' },
          'binary' => { 'type' => 'string' },
          'boolean' => { 'type' => 'boolean' },
          'decimal' => { 'type' => 'number' },
          'integer' => { 'type' => 'integer' },
          'dateTime' => { 'type' => 'string', 'format' => 'date-time' }
        }.freeze

        def self.convert(schema)
          object_schema(schema[:attributes] || [])
        end

        def self.object_schema(attributes)
          properties, required = attributes.reduce([{}, []]) do |(p, r), a|
            p[a[:name]] = attribute_schema(a)
            r << a[:name] if a[:required]
            [p, r]
          end
          { 'type' => 'object', 'properties' => properties,
            'required' => required, 'additionalProperties' => false }
        end

        def self.attribute_schema(attribute)
          schema = leaf_schema(attribute)
          return schema unless attribute[:multiValued]

          { 'type' => 'array', 'items' => schema }
        end

        def self.leaf_schema(attribute)
          if attribute[:type] == 'complex'
            object_schema(attribute[:subAttributes] || [])
          else
            with_enum(attribute)
          end
        end

        def self.with_enum(attribute)
          schema = TYPE_MAP.fetch(attribute[:type]).dup
          canonical_values = attribute[:canonicalValues]
          return schema if canonical_values.nil? || canonical_values.empty?

          schema.merge('enum' => canonical_values)
        end
      end
    end
  end
end
