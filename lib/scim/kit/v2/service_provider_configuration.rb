# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Service Provider Configuration
      class ServiceProviderConfiguration
        include Templatable
        attr_accessor :meta, :documentation_uri
        attr_reader :authentication_schemes
        attr_reader :bulk, :filter
        attr_reader :etag, :sort, :change_password, :patch

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
            x.bulk.supported = hash[:bulk][:supported]
            x.bulk.max_operations = hash[:bulk][:maxOperations]
            x.bulk.max_payload_size = hash[:bulk][:maxPayloadSize]
            x.filter.supported = hash[:filter][:supported]
            x.filter.max_results = hash[:filter][:maxResults]
            x.patch.supported = hash[:patch][:supported]
            x.change_password.supported = hash[:changePassword][:supported]
            x.sort.supported = hash[:sort][:supported]
            x.etag.supported = hash[:etag][:supported]
            hash[:authenticationSchemes]&.each do |auth|
              x.add_authentication(auth[:type], primary: auth[:primary]) do |y|
                y.description = auth[:description]
                y.documentation_uri = auth[:documentationUri]
                y.name = auth[:name]
                y.spec_uri = auth[:specUri]
              end
            end
            x
          end
        end
      end
    end
  end
end
