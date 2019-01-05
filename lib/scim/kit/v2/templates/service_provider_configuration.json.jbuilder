# frozen_string_literal: true

json.key_format! camelize: :lower
json.schemas [Scim::Kit::V2::Schema::SERVICE_PROVIDER_CONFIGURATION]
json.documentation_uri documentation_uri
json.patch do
  render patch, json: json
end
json.bulk do
  render bulk, json: json
end
json.filter do
  render filter, json: json
end
json.change_password do
  render change_password, json: json
end
json.sort do
  render sort, json: json
end
json.etag do
  render etag, json: json
end
json.authentication_schemes authentication_schemes do |authentication_scheme|
  render authentication_scheme, json: json
end
json.meta do
  render meta, json: json
end
