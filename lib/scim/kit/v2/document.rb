# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # A SCIM document received from a server. Every SCIM document names its
      # own type in "schemas" (RFC 7643 3.1), so the payload decides which
      # subclass parses it.
      class Document
        include Scim::Kit::Validatable
        include SchemaValidatable

        CONSTRUCTORS = {
          Schemas::SERVICE_PROVIDER_CONFIGURATION =>
            -> { Documents::ServiceProviderConfig },
          Schemas::SCHEMA => -> { Documents::Schema },
          Schemas::RESOURCE_TYPE => -> { Documents::ResourceType },
          Messages::LIST_RESPONSE => -> { Documents::ListResponse },
          Messages::ERROR => -> { Documents::Error }
        }.freeze

        validate :must_match_its_schema

        class << self
          # Never raises. Anything unrecognised or unparseable becomes a
          # Documents::Invalid, which answers valid? with false.
          def to_scim_document(payload, configuration: V2.configuration)
            body = parse(payload)
            constructor(body).new(body, configuration: configuration)
          rescue StandardError => error
            Scim::Kit.logger.error(error)
            Documents::Invalid.new({}, configuration: configuration)
          end

          private

          def constructor(body)
            return Documents::Invalid unless body.is_a?(Hash)

            urns = Array(body[:schemas])
            CONSTRUCTORS.find { |urn, _| urns.include?(urn) }
              &.last&.call || Documents::Invalid
          end

          def parse(payload)
            return payload if payload.is_a?(Hash) || payload.is_a?(Array)

            JSON.parse(payload.to_s, symbolize_names: true)
          end
        end

        attr_reader :configuration

        def initialize(body, configuration: V2.configuration)
          @body = body
          @configuration = configuration
        end

        def to_h
          body
        end

        def schemas
          Array(body[:schemas])
        end

        # The name of the $defs entry in schema.json that describes this
        # document. Subclasses that derive one at runtime override #json_schema.
        def definition
          nil
        end

        def json_schema
          JsonSchema.entry_point(definition)
        end

        private

        attr_reader :body

        def must_match_its_schema
          matches_json_schema?(json_schema)
        end
      end
    end
  end
end
