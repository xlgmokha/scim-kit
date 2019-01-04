# frozen_string_literal: true

require 'tilt'
require 'tilt/jbuilder'

require 'scim/kit/templatable'
require 'scim/kit/template'
require 'scim/kit/version'

require 'scim/kit/v2/attribute_type'
require 'scim/kit/v2/mutability'
require 'scim/kit/v2/resource_type'
require 'scim/kit/v2/returned'
require 'scim/kit/v2/schema'
require 'scim/kit/v2/service_provider_configuration'
require 'scim/kit/v2/uniqueness'

module Scim
  module Kit
    class Error < StandardError; end
  end
end
