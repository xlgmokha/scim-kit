# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Attribute
      class Attribute
        include Attributable
        attr_reader :type
        attr_reader :value

        def initialize(type:, value: nil)
          @type = type
          @value = value
          define_attributes_for(type.attributes)
        end

        def value=(new_value)
          case type.type
          when :string
            @value = new_value.to_s
          when :boolean
            raise ArgumentError, new_value unless [true, false].include?(new_value)

            @value = new_value
          when :decimal
            @value = new_value.to_f
          when :integer
            @value = new_value.to_i
          when :datetime
            @value = new_value.is_a?(::String) ?
              DateTime.parse(new_value) :
              new_value
          when :binary
            @value = Base64.strict_encode64(new_value)
          when :reference
            @value = new_value
          end

          if type.canonical_values && !type.canonical_values.empty?
            raise ArgumentError, new_value unless type.canonical_values.include?(new_value)
          end
        end
      end
    end
  end
end
