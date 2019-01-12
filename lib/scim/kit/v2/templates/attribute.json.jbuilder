# frozen_string_literal: true

json.key_format! camelize: :lower
if type.complex? && !type.multi_valued
  json.set! type.name do
    dynamic_attributes.values.each do |attribute|
      render attribute, json: json
    end
  end
else
  json.set! type.name, _value if renderable?
end
