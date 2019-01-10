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
        validate :validate_array, if: proc { |x| x.type.multi_valued }

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

          errors.add(type.name, I18n.t('errors.messages.blank'))
        end

        def inclusion_of_value
          return if type.canonical_values.include?(_value)

          errors.add(type.name, I18n.t('errors.messages.inclusion'))
        end

        def validate_array
          return if _value.respond_to?(:each) && _value.all? { |x| type.valid?(x) }

          errors.add(type.name, I18n.t('errors.messages.invalid'))
        end
      end
    end
  end
end
