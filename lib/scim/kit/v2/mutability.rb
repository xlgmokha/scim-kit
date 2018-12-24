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
          read_only: 'readOnly',
          read_write: 'readWrite',
          immutable: 'immutable',
          write_only: 'writeOnly'
        }.freeze

        def self.valid?(value)
          VALID.key?(value.to_sym) || VALID.value?(value)
        end
      end
    end
  end
end
