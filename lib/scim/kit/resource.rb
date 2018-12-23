module Scim
  module Kit
    class Resource
      def to_json
        JSON.generate(to_h)
      end

      def to_h
        {
          schemas: [Schema::RESOURCE_TYPE]
        }
      end
    end
  end
end
