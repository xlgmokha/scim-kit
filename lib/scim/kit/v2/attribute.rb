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
        attr_reader :_resource
        attr_reader :_value

        validate :presence_of_value, if: proc { |x| x.type.required }
        validate :inclusion_of_value, if: proc { |x| x.type.canonical_values }
        validate :validate_type

        def initialize(resource:, type:, value: nil)
          @type = type
          @_value = value
          @_resource = resource
          define_attributes_for(resource, type.attributes)
        end

        def _assign(new_value, coerce: true)
          @_value = coerce ? type.coerce(new_value) : new_value
        end

        def _value=(new_value)
          _assign(new_value, coerce: true)
        end

        def renderable?
          return false if read_only? && _resource.mode?(:client)
          return false if write_only? && _resource.mode?(:server)
          return false if write_only? && _value.nil?

          true
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

        def validate_type
          return if type.valid?(_value)

          errors.add(type.name, I18n.t('errors.messages.invalid'))
        end

        def read_only?
          type.mutability == Mutability::READ_ONLY
        end

        def write_only?
          type.mutability == Mutability::WRITE_ONLY
        end
      end
    end
  end
end
