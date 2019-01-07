# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a dynamic attribute that corresponds to a SCIM type
      module Attributable
        attr_reader :dynamic_attributes

        def define_attributes_for(types)
          @dynamic_attributes = {}.with_indifferent_access
          types.each do |type|
            dynamic_attributes[type.name.underscore] = Attribute.new(type: type)
            extend(create_module_for(type))
          end
        end

        private

        def attribute_for(name)
          dynamic_attributes[name]
        end

        def create_module_for(type)
          name = type.name.underscore.to_sym
          Module.new do
            define_method(name) do |*_args|
              attribute = attribute_for(name)
              return attribute._value if attribute.type.multi_valued

              attribute.type.complex? ? attribute : attribute._value
            end

            define_method("#{name}=") do |*args|
              attribute_for(name)._value = args[0]
            end
          end
        end
      end
    end
  end
end
