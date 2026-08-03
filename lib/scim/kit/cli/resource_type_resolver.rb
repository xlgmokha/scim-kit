# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class ResourceTypeResolver
        def initialize(client)
          @client = client
        end

        def resource_type_for(name)
          types = resource_types
          match = types.find { |x| matches?(x, name) }
          unless match
            raise UnknownResourceType.new(name, types.map { |x| x[:name] })
          end

          match
        end

        private

        attr_reader :client

        def matches?(type, name)
          type[:id]&.casecmp?(name) || type[:name]&.casecmp?(name)
        end

        def resource_types
          @resource_types ||= fetch_resource_types
        end

        def fetch_resource_types
          result = client.fetch('ResourceTypes')
          raise RequestFailed, result unless result.ok?

          types = Cli.collection(result.body)
          unless types
            raise InvalidResponse, 'expected /ResourceTypes to return a list'
          end

          types
        end
      end
    end
  end
end
