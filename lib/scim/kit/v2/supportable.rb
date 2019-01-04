# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class Supportable
        include Templatable

        attr_accessor :supported

        def initialize(*custom_attributes)
          @custom_attributes = Hash[custom_attributes.map { |x| [x, nil] }]
          @supported = false
        end

        def method_missing(method, *args)
          target = method.to_s.gsub(/=/, '').to_sym
          if @custom_attributes.key?(target)
            @custom_attributes[target] = args[0]
          else
            super
          end
        end
      end
    end
  end
end
