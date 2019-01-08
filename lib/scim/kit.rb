# frozen_string_literal: true

require 'tilt'
require 'tilt/jbuilder'
require 'active_support/core_ext/hash/indifferent_access'

require 'scim/kit/dynamic_attributes'
require 'scim/kit/templatable'
require 'scim/kit/template'
require 'scim/kit/v2'
require 'scim/kit/version'

module Scim
  module Kit
    class Error < StandardError; end
  end
end
