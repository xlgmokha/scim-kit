# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Resource
      class Resource
        include Attributable
        include Templatable

        attr_accessor :id, :external_id
        attr_reader :meta
        attr_reader :schemas

        def initialize(schemas:, location:)
          @meta = Meta.new(schemas[0].name, location)
          @schemas = schemas
          schemas.each do |schema|
            define_attributes_for(schema.attributes)
          end
        end
      end
    end
  end
end
