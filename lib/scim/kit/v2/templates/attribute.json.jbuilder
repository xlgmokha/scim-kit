# frozen_string_literal: true

json.key_format! camelize: :lower
if _type.complex? && !_type.multi_valued
  json.set! _type.name do
    dynamic_attributes.values.each do |attribute|
      render attribute, json: json
    end
  end
elsif renderable?
  json.set! _type.name, _value
end
