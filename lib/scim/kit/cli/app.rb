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

        def report(result)
          return console.report(result) if result.ok? || !settings.validate?

          console.report(
            result, V2::JsonSchema.fetch(:error).errors_for(result.body)
          )
        end

        def fetch_discovery
          result = client.discover
          return report(result) unless result.ok? && settings.validate?

          console.report_validation(
            result, conformance.discovery_errors(result.body)
          )
        end

        def fetch_list(resource_type)
          entry = resource_type_for(resource_type)
          result = client.fetch(entry.endpoint_path, query: settings.list_query)
          validate_and_report(result, entry, list: true)
        end

        def fetch_resource(resource_type, id)
          entry = resource_type_for(resource_type)
          path = "#{entry.endpoint_path}/#{URI.encode_uri_component(id)}"
          result = client.fetch(path, query: settings.resource_query)
          validate_and_report(result, entry)
        end

        def validate_and_report(result, entry, list: false)
          return report(result) unless result.ok? && settings.validate?

          configuration.load_schemas(client)
          errors = conformance.resource_errors(
            result.body,
            resource_type: entry, list: list, sparse: settings.sparse?
          )
          return report_unvalidatable(result, entry) unless errors

          console.report_validation(result, errors)
        end

        def report_unvalidatable(result, entry)
          console.warn(
            "no schema found for resource type #{entry.name.inspect}; " \
            'cannot validate the response'
          )
          console.report_unvalidated(result)
        end

        def resource_type_for(name)
          configuration.load_resource_types(client)
          configuration.resource_type_for(name)
        end

        def configuration
          @configuration ||= V2::Configuration.new
        end

        def conformance
          @conformance ||= V2::Conformance.new(configuration)
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
