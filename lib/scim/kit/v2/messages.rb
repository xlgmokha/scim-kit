# frozen_string_literal: true

module Scim
  module Kit
    module V2
      module Messages
        CORE = 'urn:ietf:params:scim:api:messages:2.0'
        BULK_REQUEST = "#{CORE}:BulkRequest".freeze
        BULK_RESPONSE = "#{CORE}:BulkResponse".freeze
        ERROR = "#{CORE}:Error".freeze
        LIST_RESPONSE = "#{CORE}:ListResponse".freeze
        PATCH_OP = "#{CORE}:PatchOp".freeze
        SEARCH_REQUEST = "#{CORE}:SearchRequest".freeze
      end
    end
  end
end
