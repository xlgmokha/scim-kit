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

        def initialize(schema:, location:)
          @meta = Meta.new(schema.id, location)
          define_attributes_for(schema.attributes)
        end
      end
    end
  end
end
