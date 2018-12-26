# frozen_string_literal: true

json.key_format! camelize: :lower
json.id id
json.name name
json.description description
json.meta do
  json.resource_type 'Schema'
  json.location location
end
json.attributes attributes do |attribute|
  render attribute, json: json
end
