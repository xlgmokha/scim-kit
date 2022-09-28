# frozen_string_literal: true

module Scim
  module Kit
    module V2
      module Messages
        CORE = 'urn:ietf:params:scim:api:messages:2.0'
        BULK_REQUEST = "#{CORE}:BulkRequest"
        BULK_RESPONSE = "#{CORE}:BulkResponse"
        ERROR = "#{CORE}:Error"
        LIST_RESPONSE = "#{CORE}:ListResponse"
        PATCH_OP = "#{CORE}:PatchOp"
        SEARCH_REQUEST = "#{CORE}:SearchRequest"
      end
    end
  end
end
