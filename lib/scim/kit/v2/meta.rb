# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a meta section
      class Meta
        include Templatable

        attr_accessor :created, :last_modified, :version
        attr_reader :location
        attr_reader :resource_type

        def initialize(resource_type, location)
          @resource_type = resource_type
          @location = location
          @version = @created = @last_modified = Time.now
        end
      end
    end
  end
end
