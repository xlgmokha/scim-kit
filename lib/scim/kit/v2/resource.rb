# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a ResourceType Schema
      # https://tools.ietf.org/html/rfc7643#section-6
      class Resource
        attr_accessor :id
        attr_accessor :name
        attr_accessor :description
        attr_accessor :endpoint
        attr_accessor :schema
        attr_reader :location

        def initialize(location:)
          @location = location
        end

        def to_json
          JSON.generate(to_h)
        end

        def to_h
          {
            meta: meta,
            schemas: [Schema::RESOURCE_TYPE],
            id: id,
            name: name,
            description: description,
            endpoint: endpoint,
            schema: schema,
            schemaExtensions: []
          }
        end

        private

        def meta
          {
            resourceType: 'ResourceType',
            location: location
          }
        end
      end
    end
  end
end
