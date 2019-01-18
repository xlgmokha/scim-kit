# frozen_string_literal: true

require 'active_model'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'
require 'tilt'
require 'tilt/jbuilder'

require 'scim/kit/dynamic_attributes'
require 'scim/kit/templatable'
require 'scim/kit/template'
require 'scim/kit/v2'
require 'scim/kit/version'

module Scim
  module Kit
    class Error < StandardError; end
    class UnknownAttributeError < Error; end
  end
end
