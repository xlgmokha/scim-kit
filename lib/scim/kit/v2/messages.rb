# frozen_string_literal: true

module Scim
  module Kit
    module V2
      module Messages
        CORE = 'urn:ietf:params:scim:api:messages:2.0'
        LIST_RESPONSE = "#{CORE}:ListResponse"
        SEARCH_REQUEST = "#{CORE}:SearchRequest"
        ERROR = "#{CORE}:Error"
      end
    end
  end
end
