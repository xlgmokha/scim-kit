# frozen_string_literal: true

require 'scim/kit/v2/attributable'
require 'scim/kit/v2/attribute'
require 'scim/kit/v2/attribute_type'
require 'scim/kit/v2/authentication_scheme'
require 'scim/kit/v2/complex_attribute_validator'
require 'scim/kit/v2/configuration'
require 'scim/kit/v2/messages'
require 'scim/kit/v2/meta'
require 'scim/kit/v2/mutability'
require 'scim/kit/v2/resource'
require 'scim/kit/v2/error'
require 'scim/kit/v2/filter'
require 'scim/kit/v2/filter/node'
require 'scim/kit/v2/filter/visitor'
require 'scim/kit/v2/resource_type'
require 'scim/kit/v2/returned'
require 'scim/kit/v2/schema'
require 'scim/kit/v2/schemas'
require 'scim/kit/v2/service_provider_configuration'
require 'scim/kit/v2/supportable'
require 'scim/kit/v2/uniqueness'
require 'scim/kit/v2/unknown_attribute'

module Scim
  module Kit
    # Version 2 of the SCIM RFC https://tools.ietf.org/html/rfc7644
    module V2
      BASE64 = %r(
        \A([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\Z
      )x.freeze
      BOOLEAN_VALUES = [true, false].freeze
      DATATYPES = {
        string: 'string',
        boolean: 'boolean',
        decimal: 'decimal',
        integer: 'integer',
        datetime: 'dateTime',
        binary: 'binary',
        reference: 'reference',
        complex: 'complex'
      }.freeze
      COERCION = {
        binary: lambda { |x|
          VALIDATIONS[:binary].call(x) ? x : Base64.strict_encode64(x)
        },
        boolean: lambda { |x|
          return true if x == 'true'
          return false if x == 'false'

          x
        },
        datetime: ->(x) { x.is_a?(::String) ? DateTime.parse(x) : x },
        decimal: ->(x) { x.to_f },
        integer: ->(x) { x.to_i },
        string: ->(x) { x.to_s }
      }.freeze
      VALIDATIONS = {
        binary: ->(x) { x.is_a?(String) && x.match?(BASE64) },
        boolean: ->(x) { BOOLEAN_VALUES.include?(x) },
        datetime: ->(x) { x.is_a?(DateTime) },
        decimal: ->(x) { x.is_a?(Float) },
        integer: lambda { |x|
          begin
            x&.integer?
          rescue StandardError
            false
          end
        },
        reference: ->(x) { x =~ /\A#{URI.regexp(%w[http https])}\z/ },
        string: ->(x) { x.is_a?(String) }
      }.freeze

      class << self
        def configuration
          @configuration ||= ::Scim::Kit::V2::Configuration.new
        end

        def configure
          yield ::Scim::Kit::V2::Configuration::Builder.new(configuration)
        end
      end
    end
  end
end
