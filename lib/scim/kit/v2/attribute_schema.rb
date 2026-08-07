# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # The JSON Schema describing a set of SCIM attribute definitions
      # (RFC 7643 7), so a server's own /Schemas can validate its resources.
      module AttributeSchema
        TYPE_MAP = {
          'string' => { 'type' => 'string' },
          'reference' => { 'type' => 'string' },
          'binary' => { 'type' => 'string' },
          'boolean' => { 'type' => 'boolean' },
          'decimal' => { 'type' => 'number' },
          'integer' => { 'type' => 'integer' },
          'dateTime' => { 'type' => 'string', 'format' => 'date-time' }
        }.each_value(&:freeze).freeze

        class << self
          def for(attributes)
            {
              'type' => 'object',
              'properties' => properties_for(attributes),
              'required' => required_for(attributes)
            }
          end

          private

          def properties_for(attributes)
            attributes.to_h { |a| [a[:name], attribute_schema(a)] }
          end

          def required_for(attributes)
            attributes.filter_map do |a|
              a[:name] if a[:required] && a[:returned] != 'never'
            end
          end

          def attribute_schema(attribute)
            schema = leaf_schema(attribute)
            return schema unless attribute[:multiValued]

            { 'type' => 'array', 'items' => schema }
          end

          def leaf_schema(attribute)
            if attribute[:type] == 'complex'
              self.for(attribute[:subAttributes] || [])
            else
              with_enum(attribute)
            end
          end

          def with_enum(attribute)
            schema = TYPE_MAP.fetch(attribute[:type]) { {} }
            canonical_values = attribute[:canonicalValues]
            return schema if canonical_values.nil? || canonical_values.empty?

            schema.merge('enum' => canonical_values)
          end
        end
      end
    end
  end
end
