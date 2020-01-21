# frozen_string_literal: true

require 'active_model'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'
require 'logger'
require 'net/hippie'
require 'pathname'
require 'tilt'
require 'tilt/jbuilder'

require 'scim/kit/dynamic_attributes'
require 'scim/kit/templatable'
require 'scim/kit/template'
require 'scim/kit/v2'
require 'scim/kit/version'

module Scim
  # @api
  module Kit
    class Error < StandardError; end
    class UnknownAttributeError < Error; end
    class NotImplementedError < Error; end
    TYPE_ERROR = ArgumentError.new(:type)

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end
