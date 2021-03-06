# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Resource
      class Resource
        include ::ActiveModel::Validations
        include Attributable
        include Templatable

        attr_reader :meta
        attr_reader :schemas
        attr_reader :raw_attributes

        validate :schema_validations

        def initialize(schemas:, location: nil, attributes: {})
          @meta = Meta.new(schemas[0]&.name, location)
          @meta.disable_timestamps
          @schemas = schemas
          @raw_attributes = attributes
          schemas.each { |x| define_attributes_for(self, x.attributes) }
          attribute(AttributeType.new(name: :id), self)
          attribute(AttributeType.new(name: :external_id), self)
          assign_attributes(attributes)
          yield self if block_given?
        end

        # Returns the current mode.
        #
        # @param type [Symbol] The mode `:server` or `:client`.
        # @return [Boolean] Returns true if the resource matches the # type of mode
        def mode?(type)
          case type.to_sym
          when :server
            meta&.location
          else
            meta&.location.nil?
          end
        end

        # Returns the name of the jbuilder template file.
        # @return [String] the name of the jbuilder template.
        def template_name
          'resource.json.jbuilder'
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
          errors.merge!(attribute.errors) unless attribute.valid?
        end
      end
    end
  end
end
