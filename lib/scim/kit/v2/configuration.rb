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
      end
    end
  end
end
