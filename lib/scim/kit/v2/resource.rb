# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Schema
      class Resource
        include Templatable
        attr_accessor :id, :external_id
        attr_reader :meta

        def initialize(schema:, location:)
          @meta = Meta.new(schema.id, location)
        end
      end
    end
  end
end
