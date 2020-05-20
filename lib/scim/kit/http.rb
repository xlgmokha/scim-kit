# frozen_string_literal: true

module Scim
  module Kit
    class Http
      attr_reader :driver, :retries

      def initialize(driver: Http.default_driver, retries: 3)
        @driver = driver
        @retries = retries
      end

      def get(uri)
        driver.with_retry(retries: retries) do |client|
          response = client.get(uri)
          ok?(response) ? JSON.parse(response.body, symbolize_names: true) : {}
        end
      rescue *Net::Hippie::CONNECTION_ERRORS => error
        Scim::Kit.logger.error(error)
        {}
      end

      def self.default_driver
        @default_driver ||= Net::Hippie::Client.new(headers: headers).tap do |http|
          http.logger = Scim::Kit.logger
          http.open_timeout = 1
          http.read_timeout = 5
          http.follow_redirects = 3
        end
      end

      def self.headers
        {
          'Accept' => 'application/scim+json',
          'Content-Type' => 'application/scim+json',
          'User-Agent' => "scim/kit #{Scim::Kit::VERSION}"
        }
      end

      private

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end
    end
  end
end
