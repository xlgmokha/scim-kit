# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Service Provider Configuration
      class ServiceProviderConfiguration
        include Templatable
        attr_accessor :documentation_uri
      end
    end
  end
end
