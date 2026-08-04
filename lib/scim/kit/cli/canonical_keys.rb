# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      module CanonicalKeys
        class << self
          def apply(schema, data)
            return data unless schema.is_a?(Hash)

            case data
            when Hash then object(schema, data)
            when Array then array(schema, data)
            else data
            end
          end

          private

          def object(schema, data)
            properties = schema['properties']
            return data unless properties.is_a?(Hash)

            declared = index(properties)
            data.to_h do |key, value|
              name = declared.fetch(key.to_s.downcase, key)
              [name, apply(properties[name], value)]
            end
          end

          def array(schema, data)
            items = schema['items']
            return data unless items.is_a?(Hash)

            data.map { |value| apply(items, value) }
          end

          def index(properties)
            properties.keys.to_h { |name| [name.downcase, name] }
          end
        end
      end
    end
  end
end
