# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      # RFC 7643 2.5 makes the null value equivalent to an unassigned
      # attribute, and omitting an unassigned attribute is only a MAY.
      # Dropping nulls before validation is what makes the two spellings
      # equivalent: "required" then reports an unassigned required attribute,
      # and every other attribute is simply absent.
      #
      # 2.5 says the same of an empty array, but that is left alone on
      # purpose: an empty collection is how a conformant server reports zero
      # results, and "Resources" is only REQUIRED when "totalResults" is
      # non-zero (RFC 7644 3.4.2).
      module UnassignedValues
        class << self
          def strip(data)
            case data
            when Hash then assigned(data)
            when Array then data.map { |value| strip(value) }
            else data
            end
          end

          private

          # A null inside a multi-valued attribute is a value the server sent,
          # not an unassigned attribute, so it stays and is reported.
          def assigned(data)
            data.each_with_object({}) do |(name, value), result|
              result[name] = strip(value) unless value.nil?
            end
          end
        end
      end
    end
  end
end
