# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class Settings
        QUERY = {
          'filter' => :filter,
          'startIndex' => :start_index,
          'count' => :count,
          'sortBy' => :sort_by,
          'sortOrder' => :sort_order,
          'attributes' => :attributes
        }.freeze

        def initialize(options, env: ENV)
          @options = options
          @env = env
        end

        def url
          @url ||= validate(options[:url] || env.fetch('SCIM_KIT_URL', nil))
        end

        def headers
          @headers ||= Array(options[:header]).to_h { |x| split_header(x) }
        end

        def list_query
          QUERY.transform_values { |name| options[name] }
        end

        def resource_query
          list_query.slice('attributes')
        end

        def validate?
          options[:validate]
        end

        def sparse?
          !options[:attributes].nil?
        end

        private

        attr_reader :options, :env

        def validate(url)
          raise Thor::Error, '--url is required' if url.to_s.empty?

          unless absolute_http?(url)
            raise Thor::Error,
              "--url must be an absolute http(s) URL, got #{url.inspect}"
          end

          url
        end

        def absolute_http?(url)
          uri = URI.parse(url)
          uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
        rescue URI::InvalidURIError
          false
        end

        def split_header(header)
          name, value = header.split(':', 2)
          if value.nil?
            raise Thor::Error,
              "malformed --header #{header.inspect} " \
              '(expected "Name: Value")'
          end

          [name.to_s.strip, value.to_s.strip]
        end
      end
    end
  end
end
