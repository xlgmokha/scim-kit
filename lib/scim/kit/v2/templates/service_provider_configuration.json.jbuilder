# frozen_string_literal: true

json.key_format! camelize: :lower
json.schemas [Scim::Kit::V2::Schema::SERVICE_PROVIDER_CONFIGURATION]
json.documentation_uri documentation_uri
json.patch do
  json.supported false
end
json.bulk do
  json.supported false
end
json.filter do
  json.supported false
end
json.change_password do
  json.supported false
end
json.sort do
  json.supported false
end
json.etag do
  json.supported false
end
json.authentication_schemes authentication_schemes do |authentication_scheme|
  render authentication_scheme, json: json
end
json.meta do
  json.location location
  json.resource_type 'ServiceProviderConfig'
  json.created created.iso8601
  json.last_modified last_modified.iso8601
  json.version version.to_i
end
