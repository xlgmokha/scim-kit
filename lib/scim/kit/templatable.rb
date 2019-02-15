# frozen_string_literal: true

module Scim
  module Kit
    # Implement methods necessary to generate json from jbuilder templates.
    module Templatable
      # Returns the JSON representation of the item.
      # @param options [Hash] the hash of options to forward to jbuilder
      # return [String] the json string
      def to_json(options = {})
        render(self, options)
      end

      # Returns the hash representation of the JSON
      # @return [Hash] the hash representation of the items JSON.
      def as_json(_options = nil)
        to_h
      end

      # Returns the hash representation of the JSON
      # @return [Hash] the hash representation of the items JSON.
      def to_h
        JSON.parse(to_json, symbolize_names: true).with_indifferent_access
      end

      # Renders the model to JSON.
      # @param model [Object] the model to render.
      # @param options [Hash] the hash of options to pass to jbuilder.
      # @return [String] the JSON.
      def render(model, options)
        Template.new(model).to_json(options)
      end

      # Returns the file name of the jbuilder template.
      # @return [String] name of the jbuilder template.
      def template_name
        "#{self.class.name.split('::').last.underscore}.json.jbuilder"
      end
    end
  end
end
