module Scim
  module Kit
    class Resource
      attr_accessor :id
      attr_accessor :name
      attr_accessor :description
      attr_accessor :endpoint
      attr_accessor :schema
      attr_reader :location

      def initialize(location:)
        @location = location
      end

      def to_json
        JSON.generate(to_h)
      end

      def to_h
        {
          meta: {
            resourceType: 'ResourceType',
            location: location,
          },
          schemas: [Schema::RESOURCE_TYPE],
          id: id,
          name: name,
          description: description,
          endpoint: endpoint,
          schema: schema,
          schemaExtensions: [],
        }
      end
    end
  end
end
