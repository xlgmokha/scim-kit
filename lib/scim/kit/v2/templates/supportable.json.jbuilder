# frozen_string_literal: true

json.key_format! camelize: :lower
json.supported supported
@custom_attributes.each do |key, value|
  json.set! key.to_s.delete('='), value
end
