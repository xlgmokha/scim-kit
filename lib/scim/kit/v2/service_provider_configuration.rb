# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Service Provider Configuration
      class ServiceProviderConfiguration
        include Templatable
        attr_reader :location
        attr_accessor :documentation_uri
        attr_accessor :created, :last_modified, :version

        def initialize(location:)
          @location = location
          @version = @created = @last_modified = Time.now
        end
      end
    end
  end
end
