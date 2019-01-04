# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class Supportable
        include Templatable

        attr_accessor :supported

        def initialize
          @supported = false
        end
      end
    end
  end
end
