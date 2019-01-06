# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Schema
      class Schema
        include Templatable

        attr_reader :id, :name, :location, :attributes
        attr_accessor :description

        def initialize(id:, name:, location:)
          @id = id
          @name = name
          @location = location
          @attributes = []
        end

        def add_attribute(name:, type: :string)
          attribute = AttributeType.new(name: name, type: type)
          yield attribute if block_given?
          @attributes << attribute
        end

        def self.build(*args)
          item = new(*args)
          yield item
          item
        end
      end
    end
  end
end
