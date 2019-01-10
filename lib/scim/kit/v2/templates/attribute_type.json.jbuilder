# frozen_string_literal: true

json.key_format! camelize: :lower
json.description description
json.multi_valued multi_valued
json.mutability mutability
json.name name.camelize(:lower)
json.required required
json.returned returned
json.type type
json.uniqueness uniqueness
json.case_exact(case_exact) if string? || reference?
json.reference_types(reference_types) if reference?
json.canonical_values(canonical_values) if canonical_values
if complex?
  json.sub_attributes attributes do |attribute|
    render attribute, json: json
  end
end
