# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Turns each JSON Schema error into an ActiveModel error, so a caller
      # cannot tell a schema violation from any other kind.
      module SchemaValidatable
        def matches_json_schema?(json_schema)
          messages = json_schema.errors_for(to_h)
          messages.each { |message| errors.add(:base, message) }
          messages.empty?
        end
      end
    end
  end
end
