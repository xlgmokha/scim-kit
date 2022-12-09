# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a dynamic attribute that corresponds to a SCIM type
      module Attributable
        include Enumerable

        # Returns a hash of the generated dynamic attributes
        # @return [Hash] the dynamic attributes keys by their name
        def dynamic_attributes
          @dynamic_attributes ||= {}.with_indifferent_access
        end

        # Defines dynamic attributes on the resource for the types provided
        # @param resource [Scim::Kit::V2::Resource] the resource to attach dynamic attributes to.
        # @param types [Array<Scim::Kit::V2::AttributeType>] the array of types
        def define_attributes_for(resource, types)
          types.each { |x| attribute(x, resource) }
        end

        # Assigns attribute values via the provided hash.
        # @param attributes [Hash] The name/values to assign.
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

        # Returns the attribute identified by the name.
        # @param name [String] the name of the attribute to return
        # @return [Scim::Kit::V2::Attribute] the attribute or {Scim::Kit::V2::UnknownAttribute}
        def attribute_for(name)
          dynamic_attributes[name.to_s.underscore] ||
            dynamic_attributes[name] ||
            UnknownAttribute.new(name)
        end

        # Returns the value associated with the attribute name
        # @param name [String] the name of the attribute
        # @return [Object] the value assigned to the attribute
        def read_attribute(name)
          attribute = attribute_for(name)
          return attribute._value if attribute._type.multi_valued

          attribute._type.complex? ? attribute : attribute._value
        end

        # Assigns the value to the attribute with the given name
        # @param name [String] the name of the attribute
        # @param value [Object] the value to assign to the attribute
        def write_attribute(name, value)
          if value.is_a?(Hash)
            attribute_for(name)&.assign_attributes(value)
          else
            attribute_for(name)._value = value
          end
        end

        # yields each attribute to the provided block
        # @param [Block] the block to yield each attribute to.
        def each
          dynamic_attributes.each do |_name, attribute|
            yield attribute
          end
        end

        private

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
          if dynamic_attributes.key?(type.name)
            key = "#{type.schema&.id}##{type.name}"
            dynamic_attributes[key] = Attribute.new(
              type: type,
              resource: resource
            )
          else
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
end
