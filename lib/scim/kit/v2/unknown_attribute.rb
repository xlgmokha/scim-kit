# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class UnknownAttribute
        include ::ActiveModel::Validations
        validate :unknown
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def _assign(*args)
          valid?
        end

        def unknown
          errors.add(name, I18n.t('errors.messages.invalid'))
        end
      end
    end
  end
end
