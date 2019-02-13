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

        def initialize
          @resource_types = {}
          @schemas = {}

          yield Builder.new(self) if block_given?
        end

        def load_from(base_url)
          uri = URI.join(base_url, 'ServiceProviderConfig')
          self.service_provider_configuration =
            ServiceProviderConfiguration.parse(client.get(uri).body)

          response = client.get(URI.join(base_url, 'Schemas'))
          schema_hashes = JSON.parse(response.body, symbolize_names: true)
          schema_hashes.each do |schema_hash|
            schema = Schema.from(schema_hash)
            schemas[schema.id] = schema
          end
          response = client.get(URI.join(base_url, 'ResourceTypes'))
          resource_types_hashes = JSON.parse(response.body, symbolize_names: true)
          resource_types_hashes.each do |resource_type_hash|
            resource_type = ResourceType.from(resource_type_hash)
            resource_types[resource_type.id] = resource_type
          end
        end

        private

        def client
          @client ||= Net::Hippie::Client.new
        end
      end
    end
  end
end
