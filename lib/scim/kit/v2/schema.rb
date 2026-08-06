# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Schema
      class Schema
        include Templatable

        attr_reader :id, :name, :attributes
        attr_accessor :meta, :description

        def initialize(id:, name:, location:)
          @id = id
          @name = name
          @description = name
          @meta = Meta.new('Schema', location)
          @meta.created = @meta.last_modified = @meta.version = nil
          @attributes = []
          yield self if block_given?
        end

        def add_attribute(name:, type: :string)
          attribute = AttributeType.new(name: name, type: type, schema: self)
          yield attribute if block_given?
          attributes << attribute
        end

        def core?
          id.include?(Schemas::CORE) || id.include?(Messages::CORE)
        end

        # The JSON Schema describing a resource of this schema, so a document
        # can be checked against the schema its server advertises.
        def to_json_schema
          AttributeSchema.for(as_json[:attributes] || [])
        end

        class << self
          def build(**args)
            item = new(**args)
            yield item
            item
          end

          def from(hash)
            Schema.new(
              id: hash[:id],
              name: hash[:name],
              location: hash[:location]
            ) { |x| assign(x, hash) }
          end

          def parse(json)
            from(JSON.parse(json, symbolize_names: true))
          end

          private

          # RFC 7643 3.1 requires no meta sub-attribute and 7 makes attributes
          # the only mandatory content, so a server may omit either. The
          # constructor already supplies a default meta.
          def assign(schema, hash)
            schema.meta = Meta.from(hash[:meta]) if hash[:meta]
            schema.description = hash[:description] if hash[:description]
            Array(hash[:attributes]).each do |x|
              schema.attributes << parse_attribute_type(x)
            end
          end

          def parse_attribute_type(hash)
            attribute_type = AttributeType.from(hash)
            hash[:subAttributes]&.each do |sub_attr_hash|
              attribute_type.attributes << parse_attribute_type(sub_attr_hash)
            end
            attribute_type
          end
        end
      end
    end
  end
end
