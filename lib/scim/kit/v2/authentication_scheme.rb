# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents the available Authentication Schemes.
      class AuthenticationScheme
        DEFAULTS = {
          httpbasic: {
            description: 'Authentication scheme using the HTTP Basic Standard',
            documentation_uri: 'http://example.com/help/httpBasic.html',
            name: 'HTTP Basic',
            spec_uri: 'http://www.rfc-editor.org/info/rfc2617'
          },
          oauthbearertoken: {
            description:
            'Authentication scheme using the OAuth Bearer Token Standard',
            documentation_uri: 'http://example.com/help/oauth.html',
            name: 'OAuth Bearer Token',
            spec_uri: 'http://www.rfc-editor.org/info/rfc6750'
          }
        }.freeze
        include Templatable
        attr_accessor :name
        attr_accessor :description
        attr_accessor :documentation_uri
        attr_accessor :spec_uri
        attr_accessor :type
        attr_accessor :primary

        def initialize
          yield self if block_given?
        end

        class << self
          def build_for(type, primary: nil)
            defaults = DEFAULTS[type.to_sym] || {}
            new do |x|
              x.type = type
              x.primary = primary
              x.description = defaults[:description]
              x.documentation_uri = defaults[:documentation_uri]
              x.name = defaults[:name]
              x.spec_uri = defaults[:spec_uri]
            end
          end

          def from(hash)
            x = build_for(hash[:type], primary: hash[:primary])
            x.description = hash[:description]
            x.documentation_uri = hash[:documentationUri]
            x.name = hash[:name]
            x.spec_uri = hash[:specUri]
            x
          end
        end
      end
    end
  end
end
