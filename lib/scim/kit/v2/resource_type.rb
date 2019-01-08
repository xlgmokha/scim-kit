# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a ResourceType Schema
      # https://tools.ietf.org/html/rfc7643#section-6
      class ResourceType
        include Templatable
        attr_accessor :id
        attr_accessor :name
        attr_accessor :description
        attr_accessor :endpoint
        attr_accessor :schema
        attr_reader :schema_extensions
        attr_reader :meta

        def initialize(location:)
          @meta = Meta.new('ResourceType', location)
          @meta.version = @meta.created = @meta.last_modified = nil
          @schema_extensions = []
        end

        def add_schema_extension(schema:, required: false)
          @schema_extensions.push(schema: schema, required: required)
        end

        def self.build(*args)
          item = new(*args)
          yield item
          item
        end
      end
    end
  end
end
