# frozen_string_literal: true

require 'parslet'

module Scim
  module Kit
    module V2
      class Filter
        # @private
        class Visitor
          VISITORS = {
            and: :visit_and,
            co: :visit_contains,
            eq: :visit_equals,
            ew: :visit_ends_with,
            ge: :visit_greater_than_equals,
            gt: :visit_greater_than,
            le: :visit_less_than_equals,
            lt: :visit_less_than,
            ne: :visit_not_equals,
            or: :visit_or,
            pr: :visit_presence,
            sw: :visit_starts_with
          }.freeze

          def visit(node)
            visitor_for(node).call(node)
          end

          protected

          def visitor_for(node)
            method(VISITORS.fetch(node.operator, :visit_unknown))
          end

          def visit_and(node)
            visit(node.left).merge(visit(node.right))
            raise error_for(:visit_and)
          end

          def visit_or(_node)
            raise error_for(:visit_or)
          end

          def visit_equals(_node)
            raise error_for(:visit_equals)
          end

          def visit_not_equals(_node)
            raise error_for(:visit_not_equals)
          end

          def visit_contains(_node)
            raise error_for(:visit_contains)
          end

          def visit_starts_with(_node)
            raise error_for(:visit_starts_with)
          end

          def visit_ends_with(_node)
            raise error_for(:visit_ends_with)
          end

          def visit_greater_than(_node)
            raise error_for(:visit_greater_than)
          end

          def visit_greater_than_equals(_node)
            raise error_for(:visit_greater_than_equals)
          end

          def visit_less_than(_node)
            raise error_for(:visit_less_than)
          end

          def visit_less_than_equals(_node)
            raise error_for(:visit_less_than_equals)
          end

          def visit_presence(_node)
            raise error_for(:visit_presence)
          end

          def visit_unknown(_node)
            raise error_for(:visit_unknown)
          end

          private

          def error_for(method)
            ::Scim::Kit::NotImplementedError.new("#{method} is not implemented")
          end
        end
      end
    end
  end
end
