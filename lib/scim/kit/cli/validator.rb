# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      module Validator
        class << self
          def errors_for(schema, data)
            JSONSchemer.schema(schema)
              .validate(CanonicalKeys.apply(schema, normalize(data)))
              .map { |error| JSONSchemer::Errors.pretty(error) }
          end

          private

          def normalize(data)
            JSON.parse(JSON.generate(data))
          end
        end
      end
    end
  end
end
