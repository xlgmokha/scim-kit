# frozen_string_literal: true

module Scim
  module Kit
    # Implement methods necessary to generate json from jbuilder templates.
    module Templatable
      def to_json(options = {})
        render(self, options)
      end

      def as_json(_options = nil)
        to_h
      end

      def to_h
        JSON.parse(to_json, symbolize_names: true).with_indifferent_access
      end

      def render(model, options)
        Template.new(model).to_json(options)
      end
    end
  end
end
