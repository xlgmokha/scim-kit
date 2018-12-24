# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Schema
      class Schema
        ERROR = 'urn:ietf:params:scim:api:messages:2.0:Error'
        GROUP = 'urn:ietf:params:scim:schemas:core:2.0:Group'
        RESOURCE_TYPE = 'urn:ietf:params:scim:schemas:core:2.0:ResourceType'
        USER = 'urn:ietf:params:scim:schemas:core:2.0:User'

        attr_reader :id, :name, :location
        attr_accessor :description

        def initialize(id:, name:, location:)
          @id = id
          @name = name
          @location = location
        end

        def to_json
          JSON.generate(to_h)
        end

        def to_h
          {
            id: id,
            name: name,
            description: description,
            meta: {
              location: location,
              resourceType: 'Schema'
            }
          }
        end
      end
    end
  end
end
