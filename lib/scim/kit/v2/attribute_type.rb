# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Attribute type
      class AttributeType
        include Templatable
        attr_accessor :canonical_values
        attr_accessor :case_exact
        attr_accessor :description
        attr_accessor :multi_valued
        attr_accessor :required
        attr_reader :mutability
        attr_reader :name, :type
        attr_reader :reference_types
        attr_reader :returned
        attr_reader :uniqueness

        def initialize(name:, type: :string)
          @name = name.to_s.underscore
          @type = type.to_sym
          @description = name
          @multi_valued = false
          @required = false
          @case_exact = false
          @mutability = Mutability::READ_WRITE
          @returned = Returned::DEFAULT
          @uniqueness = Uniqueness::NONE
          raise ArgumentError, :type unless DATATYPES[@type]
        end

        def mutability=(value)
          @mutability = Mutability.find(value)
        end

        def returned=(value)
          @returned = Returned.find(value)
        end

        def uniqueness=(value)
          @uniqueness = Uniqueness.find(value)
        end

        def add_attribute(name:, type: :string)
          attribute = AttributeType.new(name: name, type: type)
          yield attribute if block_given?
          @type = :complex
          attributes << attribute
        end

        def reference_types=(value)
          @type = :reference
          @reference_types = value
        end

        def attributes
          @attributes ||= []
        end

        def complex?
          type_is?(:complex)
        end

        def coerce(value)
          return value if value.nil?
          return value if complex?

          if multi_valued
            return value unless value.respond_to?(:to_a)

            value.to_a.map do |x|
              COERCION.fetch(type, ->(y) { y }).call(x)
            end
          else
            COERCION.fetch(type, ->(x) { x }).call(value)
          end
        end

        def valid?(value)
          if multi_valued
            return false unless value.respond_to?(:to_a)

            return value.to_a.all? { |x| validate(x) }
          end

          complex? ? valid_complex?(value) : valid_simple?(value)
        end

        private

        def validate(value)
          complex? ? valid_complex?(value) : valid_simple?(value)
        end

        def valid_simple?(value)
          VALIDATIONS[type]&.call(value)
        end

        def valid_complex?(item)
          return false unless item.is_a?(Hash)

          item.keys.each do |key|
            return false unless type_for(key)&.valid?(item[key])
          end
        end

        def type_for(name)
          name = name.to_s.underscore
          attributes.find { |x| x.name.to_s.underscore == name }
        end

        def string?
          type_is?(:string)
        end

        def reference?
          type_is?(:reference)
        end

        def type_is?(expected_type)
          type.to_sym == expected_type
        end
      end
    end
  end
end
