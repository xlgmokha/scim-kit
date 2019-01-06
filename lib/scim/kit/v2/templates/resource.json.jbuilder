# frozen_string_literal: true

json.key_format! camelize: :lower
json.id id
json.external_id external_id
json.meta do
  render meta, json: json
end
