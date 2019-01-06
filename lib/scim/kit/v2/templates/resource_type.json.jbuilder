# frozen_string_literal: true

json.key_format! camelize: :lower
json.meta do
  render meta, json: json
end
json.schemas [Scim::Kit::V2::Schemas::RESOURCE_TYPE]
json.id id
json.name name
json.description description
json.endpoint endpoint
json.schema schema
json.schema_extensions []
