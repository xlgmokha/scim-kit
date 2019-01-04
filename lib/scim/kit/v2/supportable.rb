# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a Feature
      class Supportable
        include Templatable

        attr_accessor :supported

        def initialize(*custom_attributes)
          @custom_attributes = Hash[
            custom_attributes.map { |x| ["#{x}=".to_sym, nil] }
          ]
          @supported = false
        end

        def method_missing(method, *args)
          if respond_to_missing?(method)
            @custom_attributes[method] = args[0]
          else
            super
          end
        end

        def respond_to_missing?(method, _include_private = false)
          @custom_attributes.key?(method)
        end
      end
    end
  end
end
