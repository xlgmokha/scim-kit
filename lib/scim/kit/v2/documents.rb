# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # One class per SCIM document type, each naming the definition in
      # schema.json that describes it.
      module Documents
        # RFC 7644 4 / RFC 7643 5
        class ServiceProviderConfig < Document
          def definition
            'serviceProviderConfig'
          end

          def to_model
            V2::ServiceProviderConfiguration.parse(nil, to_h)
          end
        end

        # RFC 7643 7
        class Schema < Document
          def definition
            'schema'
          end

          def to_model
            V2::Schema.from(to_h)
          end
        end

        # RFC 7643 6
        class ResourceType < Document
          def definition
            'resourceType'
          end

          def to_model
            V2::ResourceType.from(to_h)
          end
        end

        # RFC 7644 3.12
        class Error < Document
          def definition
            'error'
          end
        end

        # RFC 7644 3.4.2. The envelope is checked here and each resource it
        # carries validates as the document it says it is, so an error names
        # the resource that caused it rather than a deep JSON pointer.
        class ListResponse < Document
          def definition
            'listResponse'
          end

          def resources
            Array(to_h[:Resources]).map do |resource|
              Document.to_scim_document(resource, configuration: configuration)
            end
          end

          private

          def must_match_its_schema
            super
            must_carry_valid_resources
          end

          def must_carry_valid_resources
            resources.each_with_index do |resource, index|
              next if resource.valid?

              resource.each_error do |_, message|
                errors.add(:base, "Resources[#{index}] #{message}")
              end
            end
          end
        end

        # A payload this gem cannot recognise. It is a real object answering
        # valid? with false, so callers need no rescue.
        class Invalid < Document
          def definition
            nil
          end

          def json_schema
            nil
          end

          private

          def must_match_its_schema
            errors.add(:base, 'is not a recognised SCIM document')
          end
        end
      end
    end
  end
end
