# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Attribute type
      class AttributeType
        include Templatable
        B64 = %r(\A([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\Z).freeze
        BOOLEAN_VALUES = [true, false].freeze
        DATATYPES = {
          string: 'string',
          boolean: 'boolean',
          decimal: 'decimal',
          integer: 'integer',
          datetime: 'dateTime',
          binary: 'binary',
          reference: 'reference',
          complex: 'complex'
        }.freeze
        COERCION = {
          string: ->(x) { x.to_s },
          decimal: ->(x) { x.to_f },
          integer: ->(x) { x.to_i },
          datetime: ->(x) { x.is_a?(::String) ? DateTime.parse(x) : x },
          binary: ->(x) { Base64.strict_encode64(x) }
        }.freeze
        VALIDATIONS = {
          binary: ->(x) { x.is_a?(String) && x.match?(B64) },
          boolean: ->(x) { BOOLEAN_VALUES.include?(x) },
          datetime: ->(x) { x.is_a?(DateTime) },
          decimal: ->(x) { x.is_a?(Float) },
          integer: lambda { |x|
            begin
              x&.integer?
            rescue StandardError
              false
            end
          },
          reference: ->(x) { x =~ /\A#{URI.regexp(%w[http https])}\z/ },
          string: ->(x) { x.is_a?(String) }
        }.freeze
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
          @description = ''
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
          if type_is?(:boolean) && !BOOLEAN_VALUES.include?(value)
            raise ArgumentError, value
          end
          return value if multi_valued

          coercion = COERCION[type]
          coercion ? coercion.call(value) : value
        end

        def valid?(value)
          if complex?
            if multi_valued
              return false unless value.respond_to?(:each)

              value.each do |item|
                return false unless item.is_a?(Hash)

                item.keys.each do |key|
                  attribute = attributes.find { |x| x.name.to_s.underscore == key.to_s.underscore }
                  return false unless attribute
                  return false unless attribute.valid?(item[key])
                end
              end
            else
              return false unless value.is_a?(Hash)

              value.keys.each do |key|
                attribute = attributes.find { |x| x.name.to_s.underscore == key.to_s.underscore }
                return false unless attribute.valid?(value[key])
              end
              true
            end
          else
            if multi_valued
              return false unless value.respond_to?(:each)

              validation = VALIDATIONS[type]
              value.each do |x|
                return false unless validation&.call(x)
              end
              true
            else
              VALIDATIONS[type]&.call(value)
            end
          end
        end

        private

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
