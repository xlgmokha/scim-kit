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
            self.extend(create_module_for(type))
          end
        end

        private

        def create_module_for(type)
          name = type.name.underscore.to_sym
          Module.new do
            define_method(name) do |*args, &block|
              attribute = dynamic_attributes[name]
              attribute.type.complex? ? attribute : attribute.value
            end

            define_method("#{name}=") do |*args, &block|
              dynamic_attributes[name].value = args[0]
            end
          end
        end
      end
    end
  end
end
