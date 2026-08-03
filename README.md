# Scim::Kit

[![Build Status](https://github.com/xlgmokha/scim-kit/workflows/ci/badge.svg)](https://github.com/xlgmokha/scim-kit/actions)
[![Gem Version](https://badge.fury.io/rb/scim-kit.svg)](https://rubygems.org/gems/scim-kit)

Scim::Kit is a library with the purpose of simplifying the generation
and consumption of SCIM Schema. https://tools.ietf.org/html/rfc7643#section-2


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scim-kit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scim-kit

## Usage

```ruby
def user_schema
  Scim::Kit::V2::Schema.build(
    id: Scim::Kit::V2::Schemas::USER,
    name: "User",
    location: scim_v2_schema_url(id: Scim::Kit::V2::Schemas::USER)
  ) do |schema|
    schema.description = "User Account"
    schema.add_attribute(name: 'userName') do |x|
      x.description = "Unique identifier for the User"
      x.required = true
      x.uniqueness = :server
    end
    schema.add_attribute(name: 'password') do |x|
      x.description = "The User's cleartext password."
      x.mutability = :write_only
      x.required = false
      x.returned = :never
    end
    schema.add_attribute(name: 'emails') do |x|
      x.multi_valued = true
      x.description = "Email addresses for the user."
      x.add_attribute(name: 'value') do |y|
        y.description = "Email addresses for the user."
      end
      x.add_attribute(name: 'primary', type: :boolean) do |y|
        y.description = "A Boolean value indicating the preferred email"
      end
    end
    schema.add_attribute(name: 'groups') do |x|
      x.multi_valued = true
      x.description = "A list of groups to which the user belongs."
      x.mutability = :read_only
      x.add_attribute(name: 'value') do |y|
        y.description = "The identifier of the User's group."
        y.mutability = :read_only
      end
      x.add_attribute(name: '$ref', type: :reference) do |y|
        y.reference_types = ['User', 'Group']
        y.description = "The URI of the corresponding 'Group' resource."
        y.mutability = :read_only
      end
      x.add_attribute(name: 'display') do |y|
        y.description = "A human-readable name."
        y.mutability = :read_only
      end
    end
  end
end

puts user_schema.to_json
```

## CLI

The `scim-kit` executable reads a remote SCIM server and can check its
responses against JSON Schema.

```bash
scim-kit discover --url https://example.com/scim/v2
scim-kit list User --filter 'userName eq "bjensen"' --count 10
scim-kit get User 2819c223-7f76-453a-919d-413861904646
```

The base URL comes from `--url` or the `SCIM_KIT_URL` environment variable.
Pass credentials with `--header`, which may be repeated:

```bash
export SCIM_KIT_URL=https://example.com/scim/v2
scim-kit list User --header "Authorization: Bearer $TOKEN"
```

`list` also accepts `--start-index`, `--sort-by`, `--sort-order`, and
`--attributes`; `get` accepts `--attributes`.

### Validating a server

`--validate` checks responses against JSON Schema and exits non-zero when a
response does not conform. The body is always printed to stdout; validation
errors go to stderr.

```bash
scim-kit discover --validate
scim-kit list User --validate
```

`discover` validates `/ServiceProviderConfig`, `/Schemas`, and
`/ResourceTypes` against the RFC 7643 schemas bundled with this gem. `list`
and `get` build a schema from the target server's *own* `/Schemas` document,
so they check that a server's resources match the schema it advertises.

Validation enforces what RFC 7643 §3.1 requires of a returned resource — the
`schemas` and `id` attributes, and `meta.resourceType` when `meta` is present
— along with the types, canonical values, and required attributes the server
declares. Undeclared vendor properties are permitted, and `--attributes`
relaxes the required checks so sparse responses are not reported as errors.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/xlgmokha/scim-kit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
