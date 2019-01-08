# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class Configuration
        class Builder
          def service_provider_configuration(location:)
            @sp_config = ServiceProviderConfiguration.new(location: location)
            yield @sp_config
          end

          def apply_to(configuration)
            configuration.service_provider_configuration = @sp_config
          end
        end

        attr_accessor :service_provider_configuration

        def initialize
          builder = Builder.new
          yield builder
          builder.apply_to(self)
        end
      end
    end
  end
end
