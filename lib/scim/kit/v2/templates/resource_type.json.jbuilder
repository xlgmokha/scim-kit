# frozen_string_literal: true

json.key_format! camelize: :lower
json.meta do
  json.resource_type 'ResourceType'
  json.location location
end
json.schemas [Scim::Kit::V2::Schema::RESOURCE_TYPE]
json.id id
json.name name
json.description description
json.endpoint endpoint
json.schema schema
json.schema_extensions []
