# frozen_string_literal: true

module Scim
  module Kit
    class Http
      Result = Struct.new(:status, :body) do
        def ok?
          !status.nil? && (200..299).cover?(status)
        end
      end

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
          response = client.get(uri, headers: headers)
          Result.new(response.code.to_i, parse(response.body))
        end
      rescue *Net::Hippie::CONNECTION_ERRORS => error
        Scim::Kit.logger.error(error)
        Result.new(nil, { detail: error.message })
      end

      def self.default_driver
        @default_driver ||= Net::Hippie::Client.new(
          follow_redirects: 3,
          headers: headers,
          logger: Scim::Kit.logger,
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

      def parse(body)
        return {} if body.nil?

        JSON.parse(body, symbolize_names: true)
      rescue JSON::ParserError
        { detail: body }
      end
    end
  end
end
