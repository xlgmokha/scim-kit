# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents an application SCIM configuration.
      class Configuration
        # @private
        class Builder
          attr_reader :configuration

          def initialize(configuration)
            @configuration = configuration
          end

          def service_provider_configuration(location:)
            configuration.service_provider_configuration =
              ServiceProviderConfiguration.new(location: location)
            yield configuration.service_provider_configuration
          end

          def resource_type(id:, location:)
            configuration.resource_types[id] ||=
              ResourceType.new(location: location)
            configuration.resource_types[id].id = id
            yield configuration.resource_types[id]
          end

          def schema(id:, name:, location:)
            configuration.schemas[id] ||= Schema.new(
              id: id,
              name: name,
              location: location
            )
            yield configuration.schemas[id]
          end
        end

        attr_accessor :service_provider_configuration
        attr_accessor :resource_types
        attr_accessor :schemas

        def initialize(http: Scim::Kit::Http.new)
          @http = http
          @resource_types = {}
          @schemas = {}

          yield Builder.new(self) if block_given?
        end

        # RFC 7643 6: a resource type is addressed by its id or its name.
        def resource_type_for(name)
          match = resource_types.values.find do |x|
            x.id&.casecmp?(name) || x.name&.casecmp?(name)
          end
          return match if match

          raise UnknownResourceType.new(
            name, resource_types.values.map(&:name)
          )
        end

        def schema_for(urn)
          schemas[urn]
        end

        # The JSON Schema a resource of this type must satisfy, or nil when
        # the server never published its base schema.
        def json_schema_for(resource_type, sparse: false)
          schema = resource_type.to_json_schema(schemas: schemas)
          return nil unless schema

          JsonSchema.new(sparse ? SparseSchema.relax(schema) : schema)
        end

        # Where this resource type and the loaded schemas disagree: an
        # extension declared by /ResourceTypes that /Schemas never published.
        def disagreements_for(resource_type)
          resource_type.undeclared_extensions(schemas: schemas).map do |urn|
            "schema extension #{urn.inspect} is declared by the resource " \
              'type but missing from /Schemas'
          end
        end

        # Reads a server's three discovery documents (RFC 7644 4) and rebuilds
        # them as models. A failed request is raised rather than swallowed: a
        # silently empty configuration is not a useful outcome.
        def load_from(base_url, headers: {})
          client = Client.new(base_url, headers: headers, http: http)
          result = client.discover
          raise Scim::Kit::RequestFailed, result unless result.ok?

          body = result.body
          self.service_provider_configuration =
            ServiceProviderConfiguration.parse(
              nil, body[:service_provider_configuration]
            )
          load_items(body[:schemas], Schema, schemas)
          load_items(body[:resource_types], ResourceType, resource_types)
        end

        # Loaded one collection at a time so a caller that never validates
        # does not pay for a /Schemas request.
        def load_schemas(client)
          return if @schemas_loaded

          load_collection(client, 'Schemas', Schema, schemas)
          @schemas_loaded = true
        end

        def load_resource_types(client)
          return if @resource_types_loaded

          load_collection(client, 'ResourceTypes', ResourceType, resource_types)
          @resource_types_loaded = true
        end

        private

        attr_reader :http

        def load_collection(client, path, type, items)
          result = client.fetch(path)
          raise Scim::Kit::RequestFailed, result unless result.ok?
          raise Scim::Kit::InvalidResponse, "expected #{path} to return a list" \
            unless listable?(result.body)

          load_items(result.body, type, items)
          true
        end

        def listable?(body)
          body.is_a?(Array) || (body.is_a?(Hash) && body[:Resources].is_a?(Array))
        end

        def load_items(body, type, items)
          collection(body).each do |hash|
            item = type.from(hash)
            items[item.id] = item
          end
        end

        # RFC 7644 4 says a collection SHALL use the ListResponse form, but
        # some servers return a bare array. Read either.
        def collection(body)
          return body if body.is_a?(Array)
          return [] unless body.is_a?(Hash)

          resources = body[:Resources]
          resources.is_a?(Array) ? resources : []
        end
      end
    end
  end
end
