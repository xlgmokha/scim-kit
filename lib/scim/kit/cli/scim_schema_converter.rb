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
        }.each_value(&:freeze).freeze

        def self.convert(schema)
          object_schema(schema[:attributes] || [])
        end

        def self.object_schema(attributes)
          {
            'type' => 'object',
            'properties' => properties_for(attributes),
            'required' => required_for(attributes),
            'additionalProperties' => false
          }
        end

        def self.properties_for(attributes)
          attributes.to_h { |a| [a[:name], attribute_schema(a)] }
        end

        def self.required_for(attributes)
          attributes.filter_map { |a| a[:name] if a[:required] }
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
          schema = TYPE_MAP.fetch(attribute[:type])
          canonical_values = attribute[:canonicalValues]
          return schema if canonical_values.nil? || canonical_values.empty?

          schema.merge('enum' => canonical_values)
        end
      end
    end
  end
end
