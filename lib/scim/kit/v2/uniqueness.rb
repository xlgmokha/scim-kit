# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents the valid Uniqueness values
      class Uniqueness
        NONE = 'none'
        SERVER = 'server'
        GLOBAL = 'global'
        VALID = {
          none: NONE,
          server: SERVER,
          global: GLOBAL
        }.freeze

        def self.valid?(value)
          VALID[value.to_sym]
        end
      end
    end
  end
end
