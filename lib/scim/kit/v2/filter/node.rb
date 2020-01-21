# frozen_string_literal: true

require 'parslet'

module Scim
  module Kit
    module V2
      class Filter
        # @private
        class Node
          def initialize(hash)
            @hash = hash
          end

          def operator
            self[:operator].to_sym
          end

          def attribute
            self[:attribute].to_s
          end

          def value
            self[:value].to_s[1..-2]
          end

          def not?
            @hash.key?(:not)
          end

          def accept(visitor)
            visitor.visit(self)
          end

          def left
            self.class.new(self[:left])
          end

          def right
            self.class.new(self[:right])
          end

          def inspect
            @hash.inspect
          end

          private

          def [](key)
            @hash[key]
          end
        end
      end
    end
  end
end
