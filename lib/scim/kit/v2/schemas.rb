# frozen_string_literal: true

module Scim
  module Kit
    module V2
      module Schemas
        ROOT = 'urn:ietf:params:scim:schemas'

        CORE = "#{ROOT}:core:2.0"
        EXTENSION = "#{ROOT}:extension"
        ENTERPRISE_USER = "#{EXTENSION}:enterprise:2.0:User"
        GROUP = "#{CORE}:Group"
        RESOURCE_TYPE = "#{CORE}:ResourceType"
        SERVICE_PROVIDER_CONFIGURATION = "#{CORE}:ServiceProviderConfig"
        USER = "#{CORE}:User"
      end
    end
  end
end
