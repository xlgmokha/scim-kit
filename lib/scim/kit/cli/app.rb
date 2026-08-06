# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      # Make the request, hand the response to the library, print the result.
      class App < Thor
        def self.exit_on_failure?
          true
        end

        class_option :url, desc: 'Base URL of the SCIM server (or SCIM_KIT_URL)'
        class_option :header, type: :string, repeatable: true, default: [], desc: 'Extra header as "Name: Value" (repeatable)'
        class_option :validate, type: :boolean, default: false, desc: 'Validate the response against a JSON Schema'

        desc 'discover', "Discover a server's ServiceProviderConfig, Schemas, and ResourceTypes"
        def discover
          run { fetch_discovery }
        end

        desc 'list RESOURCE_TYPE', 'List resources of a given type'
        method_option :filter, desc: 'SCIM filter expression'
        method_option :start_index, type: :numeric, desc: 'Pagination start index'
        method_option :count, type: :numeric, desc: 'Page size'
        method_option :sort_by, desc: 'Attribute to sort by'
        method_option :sort_order, desc: 'ascending or descending'
        method_option :attributes, desc: 'Comma-separated attribute names to return'
        def list(resource_type)
          run { fetch_list(resource_type) }
        end

        desc 'get RESOURCE_TYPE ID', 'Fetch a single resource'
        method_option :attributes, desc: 'Comma-separated attribute names to return'
        def get(resource_type, id)
          run { fetch_resource(resource_type, id) }
        end

        private

        def run
          exit(yield)
        rescue RequestFailed => error
          exit(report(error.result))
        rescue Scim::Kit::Error => error
          exit(console.failure(detail: error.message))
        end

        # A failed request carries the server's Error document, so --validate
        # checks that too -- RFC 7644 3.12 defines its shape.
        def report(result)
          return console.report(result) if result.ok? || !settings.validate?

          console.report(
            result, V2::JsonSchema.fetch(:error).errors_for(result.body)
          )
        end

        def fetch_discovery
          result = client.discover
          return report(result) unless result.ok? && settings.validate?

          console.report_validation(result, discovery_errors(result.body))
        end

        # Validated by the endpoint that was asked, not by what came back: a
        # document missing its own "schemas" is exactly what needs reporting.
        def discovery_errors(body)
          body.each_with_object({}) do |(key, document), errors|
            messages = V2::JsonSchema.fetch(key).errors_for(document)
            errors[key] = messages unless messages.empty?
          end
        end

        def fetch_list(resource_type)
          entry = resource_type_for(resource_type)
          result = client.fetch(entry.endpoint_path, query: settings.list_query)
          validate_and_report(result, entry) do |schema|
            V2::JsonSchema.list_of(schema.to_h)
          end
        end

        def fetch_resource(resource_type, id)
          entry = resource_type_for(resource_type)
          path = "#{entry.endpoint_path}/#{URI.encode_uri_component(id)}"
          result = client.fetch(path, query: settings.resource_query)
          validate_and_report(result, entry)
        end

        def validate_and_report(result, entry)
          return report(result) unless result.ok? && settings.validate?

          json_schema = json_schema_for(entry)
          return console.report_unvalidated(result) unless json_schema

          json_schema = yield(json_schema) if block_given?
          console.report_validation(
            result, configuration.disagreements_for(entry) +
              json_schema.errors_for(result.body)
          )
        end

        def json_schema_for(entry)
          configuration.load_schemas(client)
          schema = configuration.json_schema_for(entry, sparse: settings.sparse?)
          return schema if schema

          console.warn(
            "no schema found for resource type #{entry.name.inspect}; " \
            'cannot validate the response'
          )
          nil
        end

        def resource_type_for(name)
          configuration.load_resource_types(client)
          configuration.resource_type_for(name)
        end

        def configuration
          @configuration ||= V2::Configuration.new
        end

        def console
          @console ||= Console.new
        end

        def settings
          @settings ||= Settings.new(options)
        end

        def client
          @client ||= V2::Client.new(settings.url, headers: settings.headers)
        end
      end
    end
  end
end
