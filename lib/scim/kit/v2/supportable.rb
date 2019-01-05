# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a Feature
      class Supportable
        include Templatable
        include DynamicAttributes

        attr_accessor :supported

        def initialize(*dynamic_attributes)
          @dynamic_attributes = Hash[
            dynamic_attributes.map { |x| ["#{x}=".to_sym, nil] }
          ]
          @supported = false
        end
      end
    end
  end
end
