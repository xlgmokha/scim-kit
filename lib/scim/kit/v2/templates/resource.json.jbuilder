# frozen_string_literal: true

json.key_format! camelize: :lower
if mode?(:server)
  json.meta do
    render meta, json: json
  end
end
json.schemas schemas.map(&:id)
json.id id if mode?(:server)
json.external_id external_id if mode?(:client) && external_id
schemas.each do |schema|
  if schema.core?
    schema.attributes.each do |type|
      attribute = dynamic_attributes[type.name]
      render attribute, json: json
    end
  else
    json.set! schema.id do
      schema.attributes.each do |type|
        attribute = dynamic_attributes["#{type.schema.id}##{type.name}"] ||
                    dynamic_attributes[type.name]
        render attribute, json: json
      end
    end
  end
end
