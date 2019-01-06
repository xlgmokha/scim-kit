# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Schema
      class Resource
        include Templatable

        attr_accessor :id, :external_id
        attr_reader :meta

        def initialize(schema:, location:)
          @meta = Meta.new(schema.id, location)
          @dynamic_attributes = Hash[
            schema.attributes.map { |x| [x.name.underscore, nil] }
          ].with_indifferent_access
        end

        def method_missing(method, *args)
          if method.match?(/=/)
            target = method.to_s.delete('=')
            return super unless respond_to_missing?(target)

            @dynamic_attributes[target] = args[0]
          else
            @dynamic_attributes[method]
          end
        end

        def respond_to_missing?(method, _include_private = false)
          @dynamic_attributes.key?(method) || super
        end
      end
    end
  end
end
