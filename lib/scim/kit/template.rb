# frozen_string_literal: true

module Scim
  module Kit
    # Represents a Jbuilder template
    class Template
      TEMPLATES_DIR = Pathname.new(File.join(__dir__, 'v2/templates/'))

      attr_reader :target

      def initialize(target)
        @target = target
      end

      def to_json(options = {})
        template.render(target, options)
      end

      private

      def template_path
        TEMPLATES_DIR.join(template_name)
      end

      def template_name
        "#{target.class.name.split('::').last.underscore}.json.jbuilder"
      end

      def template
        @template ||= Tilt.new(template_path.to_s)
      end
    end
  end
end
