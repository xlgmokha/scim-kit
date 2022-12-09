# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Attribute type
      class AttributeType
        include Templatable
        attr_accessor :canonical_values, :case_exact, :description
        attr_accessor :multi_valued, :required
        attr_reader :mutability, :name, :fully_qualified_name, :type, :attributes
        attr_reader :reference_types, :returned, :uniqueness

        def initialize(name:, type: :string, schema: nil)
          @name = name.to_s.underscore
          @fully_qualified_name = [schema&.id, @name].compact.join('#')
          @type = DATATYPES[type.to_sym] ? type.to_sym : (raise TYPE_ERROR)
          @description = name.to_s.camelize(:lower)
          @multi_valued = @required = @case_exact = false
          @mutability = Mutability::READ_WRITE
          @returned = Returned::DEFAULT
          @uniqueness = Uniqueness::NONE
          @attributes = []
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

        def complex?
          type_is?(:complex)
        end

        def coerce(value)
          return value if value.nil?
          return value if complex?

          if multi_valued
            return value unless value.respond_to?(:to_a)

            value.to_a.map { |x| coerce_single(x) }
          else
            coerce_single(value)
          end
        end

        def valid?(value)
          if multi_valued
            return false unless value.respond_to?(:to_a)

            return value.to_a.all? { |x| validate(x) }
          end

          complex? ? valid_complex?(value) : valid_simple?(value)
        end

        class << self
          def from(hash)
            x = new(name: hash[:name], type: hash[:type])
            %i[
              canonicalValues caseExact description multiValued mutability
              referenceTypes required returned uniqueness
            ].each do |y|
              x.public_send("#{y.to_s.underscore}=", hash[y]) if hash.key?(y)
            end
            x
          end
        end

        private

        def coerce_single(value)
          COERCION.fetch(type, ->(x) { x }).call(value)
        rescue StandardError => error
          Scim::Kit.logger.error(error)
          value
        end

        def validate(value)
          complex? ? valid_complex?(value) : valid_simple?(value)
        end

        def valid_simple?(value)
          VALIDATIONS[type]&.call(value)
        end

        def valid_complex?(item)
          return false unless item.is_a?(Hash)

          item.each_key do |key|
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
