# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Attribute
      class Attribute
        include ::ActiveModel::Validations
        include Attributable
        include Templatable
        attr_reader :_type
        attr_reader :_resource
        attr_reader :_value

        validate :presence_of_value, if: proc { |x| x._type.required }
        validate :inclusion_of_value, if: proc { |x| x._type.canonical_values }
        validate :validate_type

        def initialize(resource:, type:, value: nil)
          @_type = type
          @_value = value || type.multi_valued ? [] : nil
          @_resource = resource
          define_attributes_for(resource, type.attributes)
        end

        def _assign(new_value, coerce: true)
          @_value = coerce ? _type.coerce(new_value) : new_value
        end

        def _value=(new_value)
          _assign(new_value, coerce: true)
        end

        def renderable?
          return false if server_only?
          return false if client_only?
          return false if restricted?

          true
        end

        private

        def server_only?
          read_only? && _resource.mode?(:client)
        end

        def client_only?
          write_only? && (_resource.mode?(:server) || _value.blank?)
        end

        def restricted?
          _resource.mode?(:server) && _type.returned == Returned::NEVER
        end

        def presence_of_value
          return unless _type.required && _value.blank?

          errors.add(_type.name, I18n.t('errors.messages.blank'))
        end

        def inclusion_of_value
          return if _type.canonical_values.include?(_value)

          errors.add(_type.name, I18n.t('errors.messages.inclusion'))
        end

        def validate_type
          return if _type.valid?(_value)

          errors.add(_type.name, I18n.t('errors.messages.invalid'))
        end

        def read_only?
          _type.mutability == Mutability::READ_ONLY
        end

        def write_only?
          _type.mutability == Mutability::WRITE_ONLY
        end
      end
    end
  end
end
