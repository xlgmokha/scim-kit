# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a scim Service Provider Configuration
      class ServiceProviderConfiguration
        include Templatable
        attr_reader :location
        attr_accessor :documentation_uri
        attr_accessor :created, :last_modified, :version
        attr_reader :authentication_schemes

        def initialize(location:)
          @location = location
          @version = @created = @last_modified = Time.now
          @authentication_schemes = []
        end

        def add_authentication(type)
          authentication_scheme = case type.to_sym
          when :oauthbearertoken
            AuthenticationScheme.new do |x|
              x.description = 'Authentication scheme using the OAuth Bearer Token Standard'
              x.documentation_uri = 'http://example.com/help/oauth.html'
              x.name = 'OAuth Bearer Token'
              x.spec_uri = 'http://www.rfc-editor.org/info/rfc6750'
              x.type = type
            end
          when :httpbasic
            AuthenticationScheme.new do |x|
              x.description = 'Authentication scheme using the HTTP Basic Standard'
              x.documentation_uri = 'http://example.com/help/httpBasic.html'
              x.name = 'HTTP Basic'
              x.spec_uri = 'http://www.rfc-editor.org/info/rfc2617'
              x.type = type
            end
          else
            AuthenticationScheme.new do |x|
              x.type = type
            end
          end
          yield authentication_scheme if block_given?
          @authentication_schemes << authentication_scheme
        end
      end
    end
  end
end
