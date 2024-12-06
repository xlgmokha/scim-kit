# frozen_string_literal: true

module Scim
  module Kit
    module V2
      module Schemas
        ROOT = 'urn:ietf:params:scim:schemas'

        CORE = "#{ROOT}:core:2.0".freeze
        EXTENSION = "#{ROOT}:extension".freeze
        ENTERPRISE_USER = "#{EXTENSION}:enterprise:2.0:User".freeze
        GROUP = "#{CORE}:Group".freeze
        RESOURCE_TYPE = "#{CORE}:ResourceType".freeze
        SCHEMA = "#{CORE}:Schema".freeze
        SERVICE_PROVIDER_CONFIGURATION = "#{CORE}:ServiceProviderConfig".freeze
        USER = "#{CORE}:User".freeze
      end
    end
  end
end
