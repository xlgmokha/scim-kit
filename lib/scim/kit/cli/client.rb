# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class Client
        def initialize(base_url, headers: {}, http: Scim::Kit::Http.new)
          @base_url = base_url
          @headers = headers
          @http = http
        end

        def fetch(path, query: {})
          http.fetch(uri_for(path, query), headers: headers)
        end

        private

        attr_reader :base_url, :headers, :http

        def uri_for(path, query)
          uri = URI.join("#{base_url.to_s.sub(%r{/+\z}, '')}/", path)
          encoded = encode_query(query)
          uri.query = encoded unless encoded.empty?
          uri
        end

        # Percent-encode per RFC 3986 rather than as a form body, so a SCIM
        # filter arrives with %20 instead of +.
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
