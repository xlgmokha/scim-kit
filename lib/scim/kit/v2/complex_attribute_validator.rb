# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class ComplexAttributeValidator < ::ActiveModel::Validator
        def validate(item)
          if item._type.multi_valued
            item.each_value do |hash|
              validated = hash.map do |key, value|
                attribute = item.attribute_for(key)
                attribute._assign(value)
                item.errors.merge!(attribute.errors) unless attribute.valid?

                key.to_sym
              end
              not_validated = item.map { |x| x._type.name.to_sym } - validated
              not_validated.each do |key|
                attribute = item.attribute_for(key)
                attribute._assign(hash[key])
                item.errors.merge!(attribute.errors) unless attribute.valid?
              end
            end
          else
            item.each do |attribute|
              item.errors.merge!(attribute.errors) unless attribute.valid?
            end
          end
        end
      end
    end
  end
end
