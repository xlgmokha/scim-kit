# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a dynamic attribute that corresponds to a SCIM type
      module Attributable
        attr_reader :dynamic_attributes

        def define_attributes_for(resource, types)
          @dynamic_attributes ||= {}.with_indifferent_access
          types.each { |x| attribute(x, resource) }
        end

        def assign_attributes(attributes = {})
          attributes.each do |key, value|
            next if key.to_sym == :schemas

            if key.to_s.start_with?(Schemas::EXTENSION)
              assign_attributes(value)
            else
              write_attribute(key, value)
            end
          end
        end

        private

        def attribute_for(name)
          dynamic_attributes[name.to_s.underscore]
        end

        def read_attribute(name)
          attribute = attribute_for(name)
          return attribute._value if attribute._type.multi_valued

          attribute._type.complex? ? attribute : attribute._value
        end

        def write_attribute(name, value)
          if value.is_a?(Hash)
            attribute_for(name)&.assign_attributes(value)
          else
            attribute = attribute_for(name)
            raise Scim::Kit::UnknownAttributeError, name unless attribute

            attribute._value = value
          end
        end

        def create_module_for(type)
          name = type.name.to_sym
          Module.new do
            define_method(name) do |*_args|
              read_attribute(name)
            end

            define_method("#{name}=") do |*args|
              write_attribute(name, args[0])
            end
          end
        end

        def attribute(type, resource)
          dynamic_attributes[type.name] = Attribute.new(
            type: type,
            resource: resource
          )
          extend(create_module_for(type))
        end
      end
    end
  end
end
