# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class Discovery
        RESOURCES = {
          service_provider_configuration: 'ServiceProviderConfig',
          schemas: 'Schemas',
          resource_types: 'ResourceTypes'
        }.freeze

        def initialize(client)
          @client = client
        end

        def fetch
          documents = {}
          RESOURCES.each do |key, path|
            result = client.fetch(path)
            return result unless result.ok?

            documents[key] = result.body
          end
          Http::Result.new(200, documents)
        end

        def errors_for(documents)
          documents.each_with_object({}) do |(key, body), errors|
            document_errors = Validator.errors_for(
              SchemaRegistry.fetch(key), body
            )
            errors[key] = document_errors unless document_errors.empty?
          end
        end

        private

        attr_reader :client
      end
    end
  end
end
