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
        class_option :header, type: :array, default: [],
          desc: 'Extra header as "Name: Value" (repeatable)'

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
          Reporting.report(Http::Result.new(200, responses), shell)
        end

        def fetch_list(resource_type)
          uri = Cli.join_uri(url, resolve_endpoint(resource_type))
          query = list_query_string
          uri.query = query unless query.empty?
          report_fetch(uri)
        end

        def fetch_resource(resource_type, id)
          uri = Cli.join_uri(url, "#{resolve_endpoint(resource_type)}/#{id}")
          if options[:attributes]
            uri.query = URI.encode_www_form(attributes: options[:attributes])
          end
          report_fetch(uri)
        end

        def report_fetch(uri)
          Reporting.report(http.fetch(uri, headers: headers), shell)
        end

        def resolve_endpoint(resource_type)
          ResourceTypeResolver.new(http, url, headers: headers)
            .endpoint_for(resource_type)
            .delete_prefix('/')
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
