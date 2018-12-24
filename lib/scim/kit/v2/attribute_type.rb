# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Attribute type
      class AttributeType
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

        def to_h
          {
            name: name, type: type.to_s,
            description: description,
            multiValued: multi_valued,
            required: required,
            caseExact: case_exact,
            mutability: mutability,
            returned: returned,
            uniqueness: uniqueness
          }
        end
      end
    end
  end
end
