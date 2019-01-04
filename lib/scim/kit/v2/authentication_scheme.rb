# frozen_string_literal: true

module Scim
  module Kit
    module V2
      class AuthenticationScheme
        include Templatable
        attr_accessor :name
        attr_accessor :description
        attr_accessor :documentation_uri
        attr_accessor :spec_uri
        attr_accessor :type

        def initialize
          yield self if block_given?
        end
      end
    end
  end
end
