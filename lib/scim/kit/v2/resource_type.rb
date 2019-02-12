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
        attr_accessor :meta

        def initialize(location:)
          @meta = Meta.new('ResourceType', location)
          @meta.version = @meta.created = @meta.last_modified = nil
          @schema_extensions = []
        end

        def add_schema_extension(schema:, required: false)
          @schema_extensions.push(schema: schema, required: required)
        end

        class << self
          def build(*args)
            item = new(*args)
            yield item
            item
          end

          def parse(json, hash = JSON.parse(json, symbolize_names: true))
            x = new(location: hash[:location])
            x.meta = Meta.from(hash[:meta])
            %i[id name description endpoint schema].each do |key|
              x.public_send("#{key}=", hash[key])
            end
            hash[:schemaExtensions].each do |y|
              x.add_schema_extension(schema: y[:schema], required: y[:required])
            end
            x
          end
        end
      end
    end
  end
end
