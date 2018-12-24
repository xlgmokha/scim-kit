# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents the valid Returned values
      class Returned
        ALWAYS = 'always'
        NEVER = 'never'
        DEFAULT = 'default'
        REQUEST = 'request'
        VALID = {
          always: ALWAYS,
          never: NEVER,
          default: DEFAULT,
          request: REQUEST
        }.freeze

        def self.valid?(value)
          VALID[value.to_sym]
        end
      end
    end
  end
end
