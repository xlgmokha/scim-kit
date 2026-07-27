# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      module Validator
        def self.errors_for(schema, data)
          JSONSchemer.schema(schema)
            .validate(normalize(data))
            .map { |error| JSONSchemer::Errors.pretty(error) }
        end

        def self.normalize(data)
          JSON.parse(JSON.generate(data))
        end
      end
    end
  end
end
