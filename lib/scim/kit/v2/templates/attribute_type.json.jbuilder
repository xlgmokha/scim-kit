# frozen_string_literal: true

json.description description
json.multiValued multi_valued
json.mutability mutability
json.name name
json.required required
json.returned returned
json.type type
json.uniqueness uniqueness
json.caseExact(case_exact) if string? || reference?
json.referenceTypes(reference_types) if reference?
if complex?
  json.subAttributes attributes do |attribute|
    Scim::Kit::Template.new(attribute).to_json(json: json)
  end
end
