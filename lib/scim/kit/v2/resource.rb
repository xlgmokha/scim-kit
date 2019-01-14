# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Resource
      class Resource
        include ::ActiveModel::Validations
        include Attributable
        include Templatable

        attr_accessor :id, :external_id
        attr_reader :meta
        attr_reader :schemas

        validates_presence_of :id
        validate :schema_validations

        def initialize(schemas:, location: nil)
          @meta = Meta.new(schemas[0].name, location)
          @meta.disable_timestamps
          @schemas = schemas
          schemas.each do |schema|
            define_attributes_for(self, schema.attributes)
          end
          yield self if block_given?
        end

        def mode?(type)
          case type.to_sym
          when :server
            meta&.location
          else
            meta&.location.nil?
          end
        end

        def assign_attributes(attributes = {})
          attributes.each do |key, value|
            public_send(:"#{key.to_s.underscore}=", value)
          end
        end

        private

        def schema_validations
          schemas.each do |schema|
            schema.attributes.each do |type|
              validate_attribute(type)
            end
          end
        end

        def validate_attribute(type)
          attribute = attribute_for(type.name)
          errors.copy!(attribute.errors) unless attribute.valid?
        end
      end
    end
  end
end
