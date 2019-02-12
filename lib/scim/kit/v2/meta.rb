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
          @resource_type = resource_type || 'Unknown'
          @location = location
          @created = @last_modified = Time.now
          @version = @created.to_i
        end

        def disable_timestamps
          @version = @created = @last_modified = nil
        end

        def self.from(hash)
          meta = Meta.new(hash[:resourceType], hash[:location])
          meta.created = hash[:created] ? DateTime.parse(hash[:created]) : nil
          meta.last_modified = hash[:lastModified] ? DateTime.parse(hash[:lastModified]) : nil
          meta.version = hash[:version]
          meta
        end
      end
    end
  end
end
