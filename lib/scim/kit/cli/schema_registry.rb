# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      module SchemaRegistry
        DIR = File.expand_path('schemas', __dir__)
        LIST_RESPONSE = 'list_response.schema.json'
        ERROR_URN = 'urn:ietf:params:scim:api:messages:2.0:Error'

        FILES = {
          service_provider_configuration:
            'service_provider_config.schema.json',
          schemas: 'schemas.schema.json',
          resource_types: 'resource_types.schema.json',
          error: 'error.schema.json'
        }.freeze

        class << self
          def fetch(key)
            load_schema(FILES.fetch(key))
          end

          def list_response_with_items(resource_schema)
            schema = load_schema(LIST_RESPONSE)
            schema['properties']['Resources']['items'] = resource_schema
            schema
          end

          private

          def load_schema(file_name)
            JSON.parse(sources[file_name] ||= read(file_name))
          end

          def read(file_name)
            File.read(File.join(DIR, file_name))
          end

          def sources
            @sources ||= {}
          end
        end
      end
    end
  end
end
