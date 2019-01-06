# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Attribute
      class Attribute
        attr_reader :type
        attr_accessor :value

        def initialize(type:, value: nil)
          @type = type
          @value = value
        end
      end
    end
  end
end
