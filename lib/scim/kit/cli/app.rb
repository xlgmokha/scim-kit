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
          Reporting.rescue_errors(shell) { fetch_discovery }
        end

        desc 'list RESOURCE_TYPE', 'List resources of a given type'
        method_option :filter, desc: 'SCIM filter expression'
        method_option :start_index, type: :numeric, desc: 'Pagination start index'
        method_option :count, type: :numeric, desc: 'Page size'
        method_option :sort_by, desc: 'Attribute to sort by'
        method_option :sort_order, desc: 'ascending or descending'
        method_option :attributes, desc: 'Comma-separated attribute names to return'
        def list(resource_type)
          Reporting.rescue_errors(shell) { fetch_list(resource_type) }
        end

        desc 'get RESOURCE_TYPE ID', 'Fetch a single resource'
        method_option :attributes, desc: 'Comma-separated attribute names to return'
        def get(resource_type, id)
          Reporting.rescue_errors(shell) { fetch_resource(resource_type, id) }
        end

        private

        def fetch_discovery
          responses = {}
          RESOURCES.each do |key, path|
            result = http.fetch(Cli.join_uri(url, path), headers: headers)
            return Reporting.report(result, shell) unless result.ok?

            responses[key] = result.body
          end
          report_discovery(Http::Result.new(200, responses))
        end

        def report_discovery(combined)
          if options[:validate]
            Reporting.report_with_validation(
              combined, shell, discovery_errors(combined.body)
            )
          else
            Reporting.report(combined, shell)
          end
        end

        def discovery_errors(responses)
          responses.each_with_object({}) do |(key, body), errors|
            schema = SchemaRegistry.fetch(key)
            body_errors = Validator.errors_for(schema, body)
            errors[key] = body_errors unless body_errors.empty?
          end
        end

        def fetch_list(resource_type)
          uri = Cli.join_uri(url, resolve_endpoint(resource_type))
          query = list_query_string
          uri.query = query unless query.empty?
          result = http.fetch(uri, headers: headers)
          validate_and_report(result, resource_type) do |schema|
            SchemaRegistry.list_response_with_items(schema)
          end
        end

        def fetch_resource(resource_type, id)
          uri = Cli.join_uri(url, "#{resolve_endpoint(resource_type)}/#{id}")
          if options[:attributes]
            uri.query = URI.encode_www_form(attributes: options[:attributes])
          end
          result = http.fetch(uri, headers: headers)
          validate_and_report(result, resource_type)
        end

        def resolve_endpoint(resource_type)
          endpoint = resource_type_entry(resource_type)[:endpoint]
          raise MissingEndpoint, resource_type if endpoint.to_s.empty?

          endpoint.delete_prefix('/')
        end

        def resource_type_entry(resource_type)
          @resource_type_entry ||=
            resource_type_resolver.resource_type_for(resource_type)
        end

        def resource_type_resolver
          @resource_type_resolver ||= ResourceTypeResolver.new(
            http, url, headers: headers
          )
        end

        def resource_schema_resolver
          @resource_schema_resolver ||= ResourceSchemaResolver.new(
            http, url, headers: headers
          )
        end

        def validate_and_report(result, resource_type)
          unless result.ok? && options[:validate]
            return Reporting.report(result, shell)
          end

          entry = resource_type_entry(resource_type)
          schema = resource_schema_resolver.schema_for(entry)
          unless schema
            Reporting.warn_unresolvable_schema(resource_type, shell)
            return Reporting.report(result, shell)
          end

          schema = yield(schema) if block_given?
          errors = Validator.errors_for(schema, result.body)
          Reporting.report_with_validation(result, shell, errors)
        end

        def list_query_string
          URI.encode_www_form(
            {
              'filter' => options[:filter],
              'startIndex' => options[:start_index],
              'count' => options[:count],
              'sortBy' => options[:sort_by],
              'sortOrder' => options[:sort_order],
              'attributes' => options[:attributes]
            }.compact
          )
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
              raise Thor::Error, "malformed --header #{header.inspect} (expected \"Name: Value\")"
            end

            hash[name.to_s.strip] = value.to_s.strip
          end
        end

        def http
          @http ||= Scim::Kit::Http.new
        end
      end
    end
  end
end
