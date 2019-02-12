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
          attribute = AttributeType.new(name: name, type: type)
          yield attribute if block_given?
          attributes << attribute
        end

        def core?
          id.include?(Schemas::CORE) || id.include?(Messages::CORE)
        end

        def self.build(*args)
          item = new(*args)
          yield item
          item
        end

        def self.parse(json)
          hash = JSON.parse(json, symbolize_names: true)
          Schema.new(
            id: hash[:id],
            name: hash[:name],
            location: hash[:location]
          ) do |x|
            x.meta = Meta.from(hash[:meta])
            hash[:attributes].each do |attr|
              x.add_attribute(name: attr[:name], type: attr[:type]) do |y|
                y.description = attr[:description]
                y.multi_valued = attr[:multiValued]
                y.required = attr[:required]
                y.case_exact = attr[:caseExact]
                y.mutability = attr[:mutability]
                y.returned = attr[:returned]
                y.uniqueness = attr[:uniqueness]
                y.canonical_values = attr[:canonicalValues]
                y.reference_types = attr[:referenceTypes]
              end
            end
          end
        end
      end
    end
  end
end
