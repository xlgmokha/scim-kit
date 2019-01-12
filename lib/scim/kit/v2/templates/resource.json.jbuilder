# frozen_string_literal: true

json.key_format! camelize: :lower
if meta.location
  json.meta do
    render meta, json: json
  end
end
json.schemas schemas.map(&:id)
json.id id if id
json.external_id external_id if external_id
schemas.each do |schema|
  if schema.core?
    schema.attributes.each do |type|
      render dynamic_attributes[type.name], json: json
    end
  else
    json.set! schema.id do
      schema.attributes.each do |type|
        render dynamic_attributes[type.name], json: json
      end
    end
  end
end
