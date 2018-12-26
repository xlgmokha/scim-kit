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
json.canonicalValues(canonical_values) if canonical_values
if complex?
  json.subAttributes attributes do |attribute|
    render attribute, json: json
  end
end
