# frozen_string_literal: true

json.key_format! camelize: :lower
json.location location
json.resource_type resource_type
json.created created.iso8601 if created
json.last_modified last_modified.iso8601 if last_modified
json.version version if version
