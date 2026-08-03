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
          encoded = URI.encode_www_form(query.compact)
          uri.query = encoded unless encoded.empty?
          uri
        end
      end
    end
  end
end
