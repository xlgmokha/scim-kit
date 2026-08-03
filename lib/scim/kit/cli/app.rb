# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class App < Thor
        def self.exit_on_failure?
          true
        end

        class_option :url, desc: 'Base URL of the SCIM server (or SCIM_KIT_URL)'
        class_option :header, type: :array, default: [], desc: 'Extra header as "Name: Value" (repeatable)'
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
          exit(reporter.failure(error.result.body))
        rescue Error => error
          exit(reporter.failure(detail: error.message))
        end

        def fetch_discovery
          discovery = Discovery.new(client)
          result = discovery.fetch
          return reporter.report(result) unless result.ok? && options[:validate]

          reporter.report_validation(result, discovery.errors_for(result.body))
        end

        def fetch_list(resource_type)
          endpoint = resolve_endpoint(resource_type)
          result = client.fetch(endpoint, query: settings.list_query)
          validate_and_report(result, resource_type) do |schema|
            SchemaRegistry.list_response_with_items(schema)
          end
        end

        def fetch_resource(resource_type, id)
          endpoint = resolve_endpoint(resource_type)
          path = "#{endpoint}/#{URI.encode_uri_component(id)}"
          result = client.fetch(
            path, query: { 'attributes' => options[:attributes] }
          )
          validate_and_report(result, resource_type)
        end

        def resolve_endpoint(resource_type)
          endpoint = resource_type_entry(resource_type)[:endpoint]
          raise MissingEndpoint, resource_type if endpoint.to_s.empty?

          endpoint.delete_prefix('/')
        end

        def resource_type_entry(resource_type)
          resource_type_resolver.resource_type_for(resource_type)
        end

        def resource_type_resolver
          @resource_type_resolver ||= ResourceTypeResolver.new(client)
        end

        def resource_schema_resolver
          @resource_schema_resolver ||= ResourceSchemaResolver.new(client)
        end

        def validate_and_report(result, resource_type, &transform)
          return reporter.report(result) unless result.ok? && options[:validate]

          entry = resource_type_entry(resource_type)
          errors = validation.errors_for(entry, result.body, &transform)
          return reporter.report(result) unless errors

          reporter.report_validation(result, errors)
        end

        def validation
          @validation ||= ResourceValidation.new(
            resource_schema_resolver, reporter, sparse: !options[:attributes].nil?
          )
        end

        def reporter
          @reporter ||= Reporter.new(shell)
        end

        def settings
          @settings ||= Settings.new(options)
        end

        def client
          @client ||= Client.new(settings.url, headers: settings.headers)
        end
      end
    end
  end
end
