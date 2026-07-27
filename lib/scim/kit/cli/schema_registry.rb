# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      module SchemaRegistry
        DIR = File.expand_path('schemas', __dir__)

        FILES = {
          service_provider_configuration:
            'service_provider_config.schema.json',
          schemas: 'schemas.schema.json',
          resource_types: 'resource_types.schema.json'
        }.freeze

        def self.fetch(key)
          @cache ||= {}
          @cache[key] ||= load(FILES.fetch(key))
        end

        def self.list_response_with_items(resource_schema)
          schema = load('list_response.schema.json')
          schema['properties']['Resources']['items'] = resource_schema
          schema
        end

        def self.load(file_name)
          JSON.parse(File.read(File.join(DIR, file_name)))
        end
      end
    end
  end
end
