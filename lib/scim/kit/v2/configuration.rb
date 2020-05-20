# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents an application SCIM configuration.
      class Configuration
        # @private
        class Builder
          attr_reader :configuration

          def initialize(configuration)
            @configuration = configuration
          end

          def service_provider_configuration(location:)
            configuration.service_provider_configuration =
              ServiceProviderConfiguration.new(location: location)
            yield configuration.service_provider_configuration
          end

          def resource_type(id:, location:)
            configuration.resource_types[id] ||=
              ResourceType.new(location: location)
            configuration.resource_types[id].id = id
            yield configuration.resource_types[id]
          end

          def schema(id:, name:, location:)
            configuration.schemas[id] ||= Schema.new(
              id: id,
              name: name,
              location: location
            )
            yield configuration.schemas[id]
          end
        end

        attr_accessor :service_provider_configuration
        attr_accessor :resource_types
        attr_accessor :schemas

        def initialize(http: Scim::Kit::Http.new)
          @http = http
          @resource_types = {}
          @schemas = {}

          yield Builder.new(self) if block_given?
        end

        def load_from(base_url)
          base_url = "#{base_url}/"
          uri = URI.join(base_url, 'ServiceProviderConfig')
          json = http.get(uri)

          self.service_provider_configuration = ServiceProviderConfiguration.parse(json, json)

          load_items(base_url, 'Schemas', Schema, schemas)
          load_items(base_url, 'ResourceTypes', ResourceType, resource_types)
        end

        private

        attr_reader :http

        def load_items(base_url, path, type, items)
          hashes = http.get(URI.join(base_url, path))
          hashes.each do |hash|
            item = type.from(hash)
            items[item.id] = item
          end
        end
      end
    end
  end
end
