# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Attribute
      class Attribute
        include ::ActiveModel::Validations
        include Attributable
        include Templatable
        attr_reader :type
        attr_reader :_value

        validate :presence_of_value, if: proc { |x| x.type.required }
        validate :inclusion_of_value, if: proc { |x| x.type.canonical_values }

        def initialize(type:, value: nil)
          @type = type
          @_value = value
          define_attributes_for(type.attributes)
        end

        def _value=(new_value)
          @_value = type.coerce(new_value)
        end

        private

        def presence_of_value
          return unless type.required && _value.blank?

          errors.add(type.name, "can't be blank")
        end

        def inclusion_of_value
          return unless type.canonical_values && !type.canonical_values.include?(_value)

          errors.add(type.name, 'is not included in the list')
        end
      end
    end
  end
end
