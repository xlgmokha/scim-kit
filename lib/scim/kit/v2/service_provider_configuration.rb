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
        attr_accessor :authentication_schemes

        def initialize(
          location:,
          meta: Meta.new('ServiceProviderConfig', location)
        )
          @meta = meta
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
          def parse(json, hash = JSON.parse(json, symbolize_names: true))
            new(location: hash[:location]).tap { |x| assign(x, hash) }
          end

          private

          def assign(config, hash)
            config.meta = Meta.from(hash[:meta]) if hash[:meta]
            config.documentation_uri = hash[:documentationUri]
            %i[patch changePassword sort etag filter bulk].each do |key|
              next unless hash[key]

              config.send("#{key.to_s.underscore}=", Supportable.from(hash[key]))
            end
            config.authentication_schemes = Array(hash[:authenticationSchemes])
              .map { |x| AuthenticationScheme.from(x) }
          end
        end
      end
    end
  end
end
