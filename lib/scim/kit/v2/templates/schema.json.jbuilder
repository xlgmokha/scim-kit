# frozen_string_literal: true

json.id id
json.name name
json.description description
json.meta do
  json.resourceType 'Schema'
  json.location location
end
json.attributes attributes do |attribute|
  render attribute, json: json
end
