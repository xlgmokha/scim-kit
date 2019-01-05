# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Service Provider Configuration
      class ServiceProviderConfiguration
        include Templatable
        attr_reader :location
        attr_accessor :documentation_uri
        attr_reader :authentication_schemes
        attr_reader :etag, :sort, :change_password, :patch
        attr_reader :bulk, :filter, :meta

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
      end
    end
  end
end
