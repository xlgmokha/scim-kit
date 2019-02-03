# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Validates a complex attribute
      class ComplexAttributeValidator < ::ActiveModel::Validator
        def validate(item)
          if item._type.multi_valued
            multi_valued_validation(item)
          else
            item.each do |attribute|
              item.errors.merge!(attribute.errors) unless attribute.valid?
            end
          end
        end

        private

        def multi_valued_validation(item)
          item.each_value do |hash|
            validated = hash.map do |key, value|
              attribute = item.attribute_for(key)
              attribute._assign(value)
              item.errors.merge!(attribute.errors) unless attribute.valid?

              key.to_sym
            end
            validate_missing(item, hash, validated)
          end
        end

        def validate_missing(item, hash, validated)
          not_validated = item.map { |x| x._type.name.to_sym } - validated
          not_validated.each do |key|
            attribute = item.attribute_for(key)
            attribute._assign(hash[key])
            item.errors.merge!(attribute.errors) unless attribute.valid?
          end
        end
      end
    end
  end
end
