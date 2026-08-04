# frozen_string_literal: true

module Scim
  module Kit
    module Cli
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
                [keyword, strip_keyword(keyword, subschema)]
              end
            when Array
              value.map { |v| strip_required(v) }
            else
              value
            end
          end

          # Keys under 'properties' are attribute names, not schema keywords,
          # so an attribute named 'required' must not be stripped.
          def strip_keyword(keyword, subschema)
            return strip_required(subschema) unless keyword == 'properties'
            return subschema unless subschema.is_a?(Hash)

            subschema.transform_values { |v| strip_required(v) }
          end
        end
      end
    end
  end
end
