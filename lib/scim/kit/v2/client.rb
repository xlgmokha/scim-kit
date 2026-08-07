# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class Client
        def initialize(base_url, headers: {}, http: Scim::Kit::Http.new)
          @base_url = base_url
          @headers = headers
          @http = http
        end

        # RFC 7644 4 defines the three endpoints a client reads to learn what
        # a server supports.
        DISCOVERY = {
          service_provider_configuration: 'ServiceProviderConfig',
          schemas: 'Schemas',
          resource_types: 'ResourceTypes'
        }.freeze

        def fetch(path, query: {})
          http.fetch(uri_for(path, query), headers: headers)
        end

        # The three discovery documents as one result, or the first failure.
        def discover
          documents = {}
          DISCOVERY.each do |key, path|
            result = fetch(path)
            return result unless result.ok?

            documents[key] = result.body
          end
          Http::Result.new(200, documents)
        end

        private

        attr_reader :base_url, :headers, :http

        def uri_for(path, query)
          uri = URI.join("#{base_url.to_s.sub(%r{/+\z}, '')}/", path)
          raise OffOrigin.new(uri, base_url) unless same_origin?(uri)

          encoded = encode_query(query)
          uri.query = encoded unless encoded.empty?
          uri
        end

        def same_origin?(uri)
          origin(uri) == origin(URI.parse(base_url.to_s))
        end

        def origin(uri)
          [uri.scheme, uri.host, uri.port]
        end

        def encode_query(query)
          query.compact.map do |name, value|
            "#{URI.encode_uri_component(name.to_s)}=" \
              "#{URI.encode_uri_component(value.to_s)}"
          end.join('&')
        end
      end
    end
  end
end
