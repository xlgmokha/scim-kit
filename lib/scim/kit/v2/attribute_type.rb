# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Attribute type
      class AttributeType
        include Templatable
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
        attr_reader :name, :type
        attr_accessor :multi_valued
        attr_accessor :required
        attr_accessor :case_exact
        attr_accessor :description
        attr_accessor :reference_types
        attr_reader :mutability
        attr_reader :returned
        attr_reader :uniqueness

        def initialize(name:, type: :string)
          @name = name
          @type = type
          @description = ''
          @multi_valued = false
          @required = false
          @case_exact = false
          @mutability = Mutability::READ_WRITE
          @returned = Returned::DEFAULT
          @uniqueness = Uniqueness::NONE
          raise ArgumentError, :type unless DATATYPES[type.to_sym]
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
          @type = :complex
          attribute = AttributeType.new(name: name, type: type)
          yield attribute if block_given?
          attributes << attribute
        end

        private

        def attributes
          @attributes ||= []
        end

        def complex?
          type_is?(:complex)
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
