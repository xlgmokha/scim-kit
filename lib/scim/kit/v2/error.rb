# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Error
      class Error < Resource
        SCIM_TYPES = %w[
          invalidPath
          invalidSyntax
          invalidSyntax
          invalidValue
          invalidVers
          mutability
          noTarget
          sensitive
          tooMany
          uniqueness
        ].freeze

        def initialize(schemas: [self.class.default_schema])
          super(schemas: schemas)
        end

        def template_name
          'resource.json.jbuilder'
        end

        def self.default_schema
          Schema.new(id: Messages::ERROR, name: 'Error', location: nil) do |x|
            x.add_attribute(name: :scim_type) do |attribute|
              attribute.canonical_values = SCIM_TYPES
            end
            x.add_attribute(name: :detail)
            x.add_attribute(name: :status, type: :integer)
          end
        end
      end
    end
  end
end
