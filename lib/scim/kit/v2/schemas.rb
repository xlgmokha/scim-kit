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

        def self.error
          Schema.new(id: Messages::ERROR, name: 'Error', location: nil) do |schema|
            schema.add_attribute(name: :scim_type) do |attribute|
              attribute.canonical_values = [
                'invalidPath',
                'invalidSyntax',
                'invalidSyntax',
                'invalidValue',
                'invalidVers',
                'mutability',
                'noTarget',
                'sensitive',
                'tooMany',
                'uniqueness',
              ]
            end
            schema.add_attribute(name: :detail)
            schema.add_attribute(name: :status, type: :integer)
          end
        end
      end
    end
  end
end
