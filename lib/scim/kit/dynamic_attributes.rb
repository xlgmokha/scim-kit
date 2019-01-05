# frozen_string_literal: true

module Scim
  module Kit
    # Allows dynamic assignment of attributes.
    module DynamicAttributes
      def method_missing(method, *args)
        return super unless respond_to_missing?(method)

        @dynamic_attributes[method] = args[0]
      end

      def respond_to_missing?(method, _include_private = false)
        @dynamic_attributes.key?(method) || super
      end
    end
  end
end
