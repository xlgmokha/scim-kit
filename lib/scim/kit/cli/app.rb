# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class App < Thor
        RESOURCES = {
          service_provider_configuration: 'ServiceProviderConfig',
          schemas: 'Schemas',
          resource_types: 'ResourceTypes'
        }.freeze

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
          responses = {}
          RESOURCES.each do |key, path|
            result = client.fetch(path)
            return reporter.report(result) unless result.ok?

            responses[key] = result.body
          end
          report_discovery(Http::Result.new(200, responses))
        end

        def report_discovery(combined)
          return reporter.report(combined) unless options[:validate]

          reporter.report_validation(combined, discovery_errors(combined.body))
        end

        def discovery_errors(responses)
          responses.each_with_object({}) do |(key, body), errors|
            schema = SchemaRegistry.fetch(key)
            body_errors = Validator.errors_for(schema, body)
            errors[key] = body_errors unless body_errors.empty?
          end
        end

        def fetch_list(resource_type)
          endpoint = resolve_endpoint(resource_type)
          result = client.fetch(endpoint, query: list_query)
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

          schema = schema_for(resource_type)
          return reporter.report(result) unless schema

          errors = Validator.errors_for(
            prepare(schema, &transform), result.body
          )
          reporter.report_validation(result, errors)
        end

        def schema_for(resource_type)
          entry = resource_type_entry(resource_type)
          schema = resource_schema_resolver.schema_for(entry)
          if schema
            warn_undeclared_extensions
          else
            warn_unresolvable_schema(resource_type)
          end
          schema
        end

        def prepare(schema)
          schema = SparseSchema.relax(schema) if options[:attributes]
          block_given? ? yield(schema) : schema
        end

        def warn_unresolvable_schema(resource_type)
          reporter.warn(
            "no schema found for resource type #{resource_type.inspect}; " \
            'skipping validation'
          )
        end

        def warn_undeclared_extensions
          resource_schema_resolver.undeclared_extensions.each do |urn|
            reporter.warn(
              "schema extension #{urn.inspect} is declared by the resource " \
              'type but missing from /Schemas'
            )
          end
        end

        def reporter
          @reporter ||= Reporter.new(shell)
        end

        def list_query
          {
            'filter' => options[:filter],
            'startIndex' => options[:start_index],
            'count' => options[:count],
            'sortBy' => options[:sort_by],
            'sortOrder' => options[:sort_order],
            'attributes' => options[:attributes]
          }
        end

        def url
          @url ||= begin
            resolved = options[:url] || ENV.fetch('SCIM_KIT_URL', nil)
            raise Thor::Error, '--url is required' if resolved.to_s.empty?

            resolved
          end
        end

        def headers
          @headers ||= options[:header].each_with_object({}) do |header, hash|
            name, value = header.split(':', 2)
            if value.nil?
              raise Thor::Error,
                "malformed --header #{header.inspect} " \
                '(expected "Name: Value")'
            end

            hash[name.to_s.strip] = value.to_s.strip
          end
        end

        def client
          @client ||= Client.new(url, headers: headers)
        end
      end
    end
  end
end
