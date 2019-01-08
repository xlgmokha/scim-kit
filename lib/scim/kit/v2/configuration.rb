# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents an application SCIM configuration.
      class Configuration
        # @private
        class Builder
          def initialize
            @resource_types = {}
            @schemas = {}
          end

          def service_provider_configuration(location:)
            @sp_config = ServiceProviderConfiguration.new(location: location)
            yield @sp_config
          end

          def resource_type(id:, location:)
            @resource_types[id] ||= ResourceType.new(location: location)
            @resource_types[id].id = id
            yield @resource_types[id]
          end

          def schema(id:, name:, location:)
            @schemas[id] ||= Schema.new(id: id, name: name, location: location)
            yield @schemas[id]
          end

          def apply_to(configuration)
            configuration.service_provider_configuration = @sp_config
            configuration.resource_types = @resource_types
            configuration.schemas = @schemas
          end
        end

        attr_accessor :service_provider_configuration
        attr_accessor :resource_types
        attr_accessor :schemas

        def initialize
          builder = Builder.new
          yield builder
          builder.apply_to(self)
        end
      end
    end
  end
end
