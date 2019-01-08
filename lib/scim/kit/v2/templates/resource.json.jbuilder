# frozen_string_literal: true

json.key_format! camelize: :lower
json.schemas schemas.map(&:id)
json.id id
json.external_id external_id
json.meta do
  render meta, json: json
end
schemas.each do |schema|
  if schema.core?
    schema.attributes.each do |type|
      render dynamic_attributes[type.name.underscore], json: json
    end
  else
    json.set! schema.id do
      schema.attributes.each do |type|
        render dynamic_attributes[type.name.underscore], json: json
      end
    end
  end
end
