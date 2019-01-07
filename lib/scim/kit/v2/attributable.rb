# frozen_string_literal: true

module Scim
  module Kit
    module V2
      module Attributable
        def define_attributes_for(types)
          @dynamic_attributes = Hash[
            types.map do |x|
              [x.name.underscore, Attribute.new(type: x)]
            end
          ].with_indifferent_access
        end

        def method_missing(method, *args)
          if method.match?(/=/)
            target = method.to_s.delete('=')
            return super unless respond_to_missing?(target)

            @dynamic_attributes[target].value = args[0]
          else
            @dynamic_attributes[method].value
          end
        end

        def respond_to_missing?(method, _include_private = false)
          @dynamic_attributes.key?(method) || super
        end
      end
    end
  end
end
