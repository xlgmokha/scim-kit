# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Attribute type
      class AttributeType
        VALID = {
          string: 'string',
          boolean: 'boolean',
          decimal: 'decimal',
          integer: 'integer',
          datetime: 'dateTime',
          reference: 'reference',
          complex: 'complex'
        }.freeze
        attr_reader :name, :type
        attr_accessor :multi_valued
        attr_accessor :required
        attr_accessor :case_exact
        attr_accessor :description
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
          @type = :complex
          attribute = AttributeType.new(name: name, type: type)
          yield attribute if block_given?
          @attributes << attribute
        end

        def to_h
          if complex?
            {
              name: name, type: type.to_s,
              description: description,
              multiValued: multi_valued,
              required: required,
              mutability: mutability,
              returned: returned,
              uniqueness: uniqueness,
              subAttributes: @attributes.map(&:to_h)
            }
          else
            x = {
              name: name, type: type.to_s,
              description: description,
              multiValued: multi_valued,
              required: required,
              mutability: mutability,
              returned: returned,
              uniqueness: uniqueness
            }
            x[:caseExact] = case_exact if string?
            x
          end
        end

        private

        def complex?
          type.to_sym == :complex
        end

        def string?
          type.to_sym == :string
        end
      end
    end
  end
end
