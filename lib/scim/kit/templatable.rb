# frozen_string_literal: true

module Scim
  module Kit
    # Implement methods necessary to generate json from jbuilder templates.
    module Templatable
      def to_json
        Template.new(self).to_json
      end

      def to_h
        JSON.parse(to_json, symbolize_names: true)
      end
    end
  end
end
