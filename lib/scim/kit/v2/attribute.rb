# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Attribute
      class Attribute
        include Attributable
        include Templatable
        attr_reader :type
        attr_reader :_value

        def initialize(type:, value: nil)
          @type = type
          @_value = value
          define_attributes_for(type.attributes)
        end

        def _value=(new_value)
          @_value = type.coerce(new_value)

          if type.canonical_values &&
             !type.canonical_values.empty? &&
             !type.canonical_values.include?(new_value)
            raise ArgumentError, new_value
          end
        end
      end
    end
  end
end
