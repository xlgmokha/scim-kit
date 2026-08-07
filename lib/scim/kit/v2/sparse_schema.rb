# frozen_string_literal: true

module Scim
  module Kit
    module V2
      module SparseSchema
        ALWAYS_RETURNED = %w[schemas id].freeze

        class << self
          def relax(schema)
            strip_required(schema).merge('required' => ALWAYS_RETURNED)
          end

          private

          def strip_required(value)
            case value
            when Hash
              value.except('required').to_h do |keyword, subschema|
                [keyword, strip_under(keyword, subschema)]
              end
            when Array
              value.map { |v| strip_required(v) }
            else
              value
            end
          end

          def strip_under(keyword, subschema)
            return strip_required(subschema) unless keyword == 'properties'

            strip_each_attribute(subschema)
          end

          def strip_each_attribute(attributes)
            return attributes unless attributes.is_a?(Hash)

            attributes.transform_values { |subschema| strip_required(subschema) }
          end
        end
      end
    end
  end
end
