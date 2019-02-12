# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Service Provider Configuration
      class ServiceProviderConfiguration
        include Templatable
        attr_accessor :bulk, :filter
        attr_accessor :etag, :sort, :change_password, :patch
        attr_accessor :meta, :documentation_uri
        attr_reader :authentication_schemes

        def initialize(location:)
          @meta = Meta.new('ServiceProviderConfig', location)
          @authentication_schemes = []
          @etag = Supportable.new
          @sort = Supportable.new
          @change_password = Supportable.new
          @patch = Supportable.new
          @bulk = Supportable.new(:max_operations, :max_payload_size)
          @filter = Supportable.new(:max_results)
        end

        def add_authentication(type, primary: nil)
          scheme = AuthenticationScheme.build_for(type, primary: primary)
          yield scheme if block_given?
          @authentication_schemes << scheme
        end

        class << self
          def parse(json)
            hash = JSON.parse(json, symbolize_names: true)
            x = new(location: hash[:location])
            x.meta = Meta.from(hash[:meta])
            x.documentation_uri = hash[:documentationUri]
            %i[patch changePassword sort etag filter bulk].each do |key|
              x.send("#{key.to_s.underscore}=", Supportable.from(hash[key]))
            end
            hash[:authenticationSchemes]&.each do |auth|
              x.authentication_schemes << AuthenticationScheme.from(auth)
            end
            x
          end
        end
      end
    end
  end
end
