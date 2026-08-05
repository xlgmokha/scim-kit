# frozen_string_literal: true

json.key_format! camelize: :lower
json.meta do
  render meta, json: json
end
json.schemas [Scim::Kit::V2::Schemas::SCHEMA]
json.id id
json.name name
json.description description
json.attributes attributes do |attribute|
  render attribute, json: json
end
