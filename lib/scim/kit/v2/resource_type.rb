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

        # RFC 7643 6: the endpoint is relative to the base URL, so a leading
        # slash would resolve against the host rather than the base.
        def endpoint_path
          raise Scim::Kit::MissingEndpoint, name || id if endpoint.to_s.empty?

          endpoint.delete_prefix('/')
        end

        # The JSON Schema for a resource of this type: the RFC 7643 3.1
        # common attributes, the base schema's own attributes, and each
        # declared extension namespaced under its URN (3.3).
        # Returns nil when the base schema is not among those given.
        def to_json_schema(schemas:)
          core = schemas[schema]
          return nil unless core

          ResourceSchema.new(self, schemas, core).to_h
        end

        # The extension URNs this type declares that the given schemas omit,
        # which means /ResourceTypes and /Schemas disagree.
        def undeclared_extensions(schemas:)
          schema_extensions
            .map { |x| x[:schema] }
            .reject { |urn| schemas.key?(urn) }
        end

        class << self
          def build(**args)
            item = new(**args)
            yield item
            item
          end

          def from(hash)
            x = new(location: hash[:location])
            # RFC 7643 6 makes schemaExtensions OPTIONAL and requires no meta
            # sub-attribute, so a server may omit either.
            x.meta = Meta.from(hash[:meta]) if hash[:meta]
            %i[id name description endpoint schema].each do |key|
              x.public_send("#{key}=", hash[key])
            end
            Array(hash[:schemaExtensions]).each do |y|
              x.add_schema_extension(schema: y[:schema], required: y[:required])
            end
            x
          end

          def parse(json)
            from(JSON.parse(json, symbolize_names: true))
          end
        end
      end
    end
  end
end
