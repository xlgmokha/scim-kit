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
json.authentication_schemes []
