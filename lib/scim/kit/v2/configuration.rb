# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class Configuration
        class Builder
          def initialize
            @resource_types = {}
          end

          def service_provider_configuration(location:)
            @sp_config = ServiceProviderConfiguration.new(location: location)
            yield @sp_config
          end

          def resource_type(id:, location:)
            @resource_types[id] ||= ResourceType.new(location: location)
            yield @resource_types[id]
          end

          def apply_to(configuration)
            configuration.service_provider_configuration = @sp_config
            configuration.resource_types = @resource_types
          end
        end

        attr_accessor :service_provider_configuration
        attr_accessor :resource_types

        def initialize
          builder = Builder.new
          yield builder
          builder.apply_to(self)
        end
      end
    end
  end
end
