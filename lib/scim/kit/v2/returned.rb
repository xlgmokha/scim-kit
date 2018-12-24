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
          always: 'always',
          never: 'never',
          default: 'default',
          request: 'request'
        }.freeze

        def self.valid?(value)
          VALID[value.to_sym]
        end
      end
    end
  end
end
