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
              value.except('required')
                .transform_values { |v| strip_required(v) }
            when Array
              value.map { |v| strip_required(v) }
            else
              value
            end
          end
        end
      end
    end
  end
end
