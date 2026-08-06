# frozen_string_literal: true

require 'active_model'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'
require 'json_schemer'
require 'logger'
require 'net/hippie'
require 'pathname'
require 'tilt'
require 'tilt/jbuilder'

require 'scim/kit/dynamic_attributes'
require 'scim/kit/http'
require 'scim/kit/templatable'
require 'scim/kit/template'
require 'scim/kit/validatable'
require 'scim/kit/v2'
require 'scim/kit/version'

module Scim
  # @api
  module Kit
    class Error < StandardError; end
    class UnknownAttributeError < Error; end
    class NotImplementedError < Error; end
    class InvalidResponse < Error; end

    class RequestFailed < Error
      attr_reader :result

      def initialize(result)
        @result = result
        super("request failed with status #{result.status.inspect}")
      end
    end

    class UnknownResourceType < Error
      def initialize(name, known_names)
        super(
          "unknown resource type #{name.inspect} " \
          "(known: #{known_names.join(', ')})"
        )
      end
    end

    class MissingEndpoint < Error
      def initialize(name)
        super("resource type #{name.inspect} has no endpoint")
      end
    end

    # RFC 7643 section 6 defines a resource type endpoint as relative to the
    # base URL. A server that advertises an absolute one on another origin
    # would otherwise be handed the credentials meant for the base URL.
    class OffOrigin < Error
      def initialize(uri, base_url)
        super(
          "refusing to send a request for #{base_url} to #{uri}, " \
          'which is a different origin'
        )
      end
    end

    TYPE_ERROR = ArgumentError.new(:type)

    def self.logger
      @logger ||= Logger.new($stdout)
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end
