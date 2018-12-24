# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents the valid Mutability values
      class Mutability
        READ_ONLY = 'readOnly'
        READ_WRITE = 'readWrite'
        IMMUTABLE = 'immutable'
        WRITE_ONLY = 'writeOnly'
        VALID = {
          read_only: READ_ONLY,
          read_write: READ_WRITE,
          immutable: IMMUTABLE,
          write_only: WRITE_ONLY
        }.freeze

        def self.valid?(value)
          VALID.key?(value.to_sym) || VALID.value?(value)
        end
      end
    end
  end
end
