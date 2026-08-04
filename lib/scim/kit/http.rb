# frozen_string_literal: true

module Scim
  module Kit
    class Http
      Result = Struct.new(:status, :body) do
        def ok?
          !status.nil? && (200..299).cover?(status)
        end
      end

      MAX_REDIRECTS = 3

      attr_reader :driver, :retries

      def initialize(driver: Http.default_driver, retries: 3)
        @driver = driver
        @retries = retries
      end

      def get(uri)
        result = fetch(uri)
        result.ok? ? result.body : {}
      end

      def fetch(uri, headers: {})
        driver.with_retry(retries: retries) do |client|
          response = get_following_redirects(client, uri, headers)
          Result.new(response.code.to_i, parse(response.body))
        end
      rescue *Net::Hippie::CONNECTION_ERRORS => error
        Scim::Kit.logger.error(error)
        Result.new(nil, { detail: error.message })
      end

      # No :logger here on purpose -- net-hippie hands it to
      # Net::HTTP#set_debug_output, which dumps raw requests (credentials
      # included) to the log.
      def self.default_driver
        @default_driver ||= Net::Hippie::Client.new(
          follow_redirects: 0,
          headers: headers,
          open_timeout: 1,
          read_timeout: 5
        )
      end

      def self.headers
        {
          'Accept' => 'application/scim+json',
          'Content-Type' => 'application/scim+json',
          'User-Agent' => "scim/kit #{Scim::Kit::VERSION}"
        }
      end

      private

      # net-hippie rebuilds the redirected request without the per-request
      # headers, so follow redirects here to keep them.
      def get_following_redirects(client, uri, headers, limit: MAX_REDIRECTS)
        uri = URI.parse(uri.to_s)
        response = client.get(uri, headers: headers)
        location = response['location'] if response.is_a?(Net::HTTPRedirection)
        return response if limit.zero? || location.to_s.empty?

        target = uri.merge(location)
        get_following_redirects(
          client, target, forwardable(headers, uri, target), limit: limit - 1
        )
      end

      def forwardable(headers, from, to)
        return headers if origin(from) == origin(to)

        headers.reject { |name, _| name.to_s.casecmp?('authorization') }
      end

      def origin(uri)
        [uri.scheme, uri.host, uri.port]
      end

      def parse(body)
        return {} if body.nil?

        JSON.parse(body, symbolize_names: true)
      rescue JSON::ParserError
        { detail: body }
      end
    end
  end
end
