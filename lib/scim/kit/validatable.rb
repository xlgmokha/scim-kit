# frozen_string_literal: true

module Scim
  module Kit
    # Gives a model ActiveModel validation plus a protocol for handing its
    # errors to a parent, so a document can validate the objects it contains
    # and re-attribute their errors onto itself.
    module Validatable
      extend ::ActiveSupport::Concern
      include ::ActiveModel::Validations

      def each_error
        errors.each { |error| yield error.attribute, error.message }
      end
    end
  end
end
