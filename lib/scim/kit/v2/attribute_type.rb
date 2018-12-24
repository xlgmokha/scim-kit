# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Attribute type
      class AttributeType
        attr_reader :name, :type

        def initialize(name:, type: :string, overrides: {})
          @name = name
          @type = type
          @overrides = defaults.merge(overrides)
          ensure_valid!(@overrides)
        end

        def to_h
          @overrides
        end

        private

        def ensure_valid!(overrides)
          valid_mutability!(overrides[:mutability])
          valid_returned!(overrides[:returned])
          valid_uniqueness!(overrides[:uniqueness])
        end

        def valid_mutability!(mutability)
          raise ArgumentError, :mutability unless Mutability.valid?(mutability)
        end

        def valid_returned!(returned)
          raise ArgumentError, :returned unless Returned.valid?(returned)
        end

        def valid_uniqueness!(uniqueness)
          raise ArgumentError, :uniqueness unless Uniqueness.valid?(uniqueness)
        end

        def defaults
          {
            name: name, type: type.to_s, description: '',
            multiValued: false, required: false, caseExact: false,
            mutability: Mutability::READ_WRITE,
            returned: Returned::DEFAULT,
            uniqueness: Uniqueness::NONE
          }
        end
      end
    end
  end
end
