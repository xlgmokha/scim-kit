# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2026-08-04
### Security
- Stop writing credentials to the log. `Scim::Kit::Http` passed its
  logger to `Net::HTTP#set_debug_output`, which dumps the raw request,
  so any consumer of `Http#fetch(headers:)` printed its bearer token to
  the default `$stdout` logger.
- Stop forwarding credentials across a redirect to another origin, and
  keep per-request headers when following a same-origin redirect.
  net-hippie rebuilds the redirected request without them, so a redirect
  previously dropped `Authorization` and reported a 401 for a valid
  token.

### Added
- Add a `scim-kit` executable with `discover`, `list`, and `get`
  commands for reading a remote SCIM server's configuration and
  resources. This adds `thor` and `json_schemer` as runtime
  dependencies; `require 'scim/kit'` does not load either.
- Add a `--validate` flag to `discover`, `list`, and `get` for checking
  responses against a JSON Schema (built-in RFC 7643 schemas for
  `discover`; derived from the target server's own `/Schemas` for
  `list`/`get`).
- Validate what RFC 7643 section 3.1 requires of a returned resource
  (`schemas` and `id`), which were previously accepted when absent.
  `id` stays optional for `ResourceType` and `ServiceProviderConfig`
  per section 6, and every `meta` sub-attribute is optional.
- Warn when a resource type declares a schema extension that the
  server's `/Schemas` does not publish.

### Fixed
- Match attribute names case insensitively, as RFC 7643 section 2.1
  requires. A server that spelled an attribute differently from its own
  schema was reported as missing a required attribute, and a wrong
  value nested under such a name went unreported entirely. Validation
  errors still name the attribute as the schema declares it.
- Treat a success response with an unparseable body as a failure rather
  than returning `{ detail: <raw body> }` for a caller to iterate.
- Exit non-zero when `--validate` cannot be carried out — for example
  when `/Schemas` is unreachable — so a CI job gating on the exit code
  no longer passes having validated nothing.
- Send every repeated `--header` flag. Thor overwrites an `:array`
  option on each occurrence, so only the last one survived and requests
  went out without their credentials.
- Percent-encode query values per RFC 3986, so a SCIM filter arrives as
  `userName%20eq%20%22bj%22` rather than form-encoded with `+`.
- Reject a `--url` that is not an absolute http(s) URL instead of
  printing a `URI::BadURIError` backtrace.
- Keep schema properties named `required` under `--attributes`, which
  were previously stripped as if they were the schema keyword.
- Stop reporting valid responses as invalid: undeclared vendor
  properties are now permitted, and `--attributes` relaxes required
  checks so sparse responses pass.
- Stop raising `KeyError` when a server's `/Schemas` omits an attribute
  `type` or uses an unrecognized one.
- Escape resource ids when building request URIs, which previously
  raised `URI::InvalidURIError` for ids containing a space.
- Resolve each resource type independently so a second `list`/`get` in
  the same process no longer reuses the first lookup.

### Changed
- Require Ruby 3.3 or newer. Ruby 3.2 reached end of life on
  2026-03-31 and no longer receives security fixes.
- Require `thor` 1.2 or newer for `Thor::Shell::Basic#say_error`.

## [0.8.0] - 2026-03-31
### Changed
- Allow using activemodel version 8+

## [0.7.2] - 2024-12-05
### Fixed
- Change references to string during validation

## [0.7.1] - 2022-12-12
### Fixed
- Add support for duplicate attribute names

## [0.7.0] - 2022-09-28
### Added
- Add constant for 'urn:ietf:params:scim:api:messages:2.0:BulkRequest' [RFC-7644](https://www.rfc-editor.org/rfc/rfc7644.html#section-3.7)
- Add constant for 'urn:ietf:params:scim:api:messages:2.0:BulkResponse' [RFC-7644](https://www.rfc-editor.org/rfc/rfc7644.html#section-3.7)
- Add constant for 'urn:ietf:params:scim:api:messages:2.0:PatchOp' [RFC-7644](https://www.rfc-editor.org/rfc/rfc7644.html#section-3.5.2)
- Add constant for 'urn:ietf:params:scim:schemas:core:2.0:Schema' [RFC-7643](https://www.rfc-editor.org/rfc/rfc7643.html#section-7)

## [0.6.0] - 2022-05-23
### Added
- Add support for Ruby 3.1

### Removed

- Drop support for Ruby 2.5
- Drop support for Ruby 2.6

## [0.5.3] - 2022-05-13
### Fixed

- fix: change `status` attribute to type string in [error schema](https://www.rfc-editor.org/rfc/rfc7644.html#section-3.12)
- fix: remove duplicate `invalidSyntax`
- fix: add mising `invalidFilter`

## [0.5.2] - 2020-05-20
### Fixed

- fix: Parse sub attributes from schema https://github.com/xlgmokha/scim-kit/pull/38

## [0.5.1] - 2020-05-20
### Fixed
- Specify `Accept: application/scim+json` header when discovering a SCIM API.
- Specify `Content-Type: application/scim+json` header when discovering a SCIM API.
- Specify `User-Agent: scim/kit <version>` header when discovering a SCIM API.
- Follow HTTP redirects when discovering a SCIM API.
- Retry 3 times with backoff + jitter when a connection to a SCIM discovery API fails.
- Specify a 1 second open timeout.
- Specify a 5 second read timeout.

## [0.5.0] - 2020-01-21
### Added
- Add API to traverse a SCIM filter AST

## [0.4.0] - 2019-06-15
### Added
- add implementation of SCIM 2.0 filter parser. [RFC-7644](https://tools.ietf.org/html/rfc7644#section-3.4.2.2)

## [0.3.2] - 2019-02-23
### Changed
- camelize the default description of attribute names.

## [0.3.1] - 2019-02-23
### Changed
- fix bug in `Scim::Kit::V2.configure`

## [0.3.0] - 2019-02-21
### Added
- add ServiceProviderConfiguration JSON parsing
- add Schema JSON parsing
- add Resource Type JSON parsing

## [0.2.16] - 2019-02-03
### Added
- Default logger
- Attributes now implement Enumerable
- Attributable#attribute\_for now returns a null object instead of nil.
- Validations for multi valued attributes
- Validations for complex attributes
- rescue errors from type coercion.

### Changed
- \_assign does not coerce values by default.
- errors are merged together instead of overwritten during attribute validation.

[Unreleased]: https://github.com/xlgmokha/scim-kit/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/xlgmokha/scim-kit/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/xlgmokha/scim-kit/compare/v0.7.2...v0.8.0
[0.7.2]: https://github.com/xlgmokha/scim-kit/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/xlgmokha/scim-kit/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/xlgmokha/scim-kit/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/xlgmokha/scim-kit/compare/v0.5.3...v0.6.0
[0.5.3]: https://github.com/xlgmokha/scim-kit/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/xlgmokha/scim-kit/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/xlgmokha/scim-kit/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/xlgmokha/scim-kit/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/xlgmokha/scim-kit/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/xlgmokha/scim-kit/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/xlgmokha/scim-kit/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/xlgmokha/scim-kit/compare/v0.2.16...v0.3.0
[0.2.16]: https://github.com/xlgmokha/scim-kit/compare/v0.2.15...v0.2.16
[0.2.15]: https://github.com/xlgmokha/scim-kit/compare/v0.2.14...v0.2.15
[0.2.14]: https://github.com/xlgmokha/scim-kit/compare/v0.2.13...v0.2.14
[0.2.13]: https://github.com/xlgmokha/scim-kit/compare/v0.2.12...v0.2.13
[0.2.12]: https://github.com/xlgmokha/scim-kit/compare/v0.2.11...v0.2.12
[0.2.11]: https://github.com/xlgmokha/scim-kit/compare/v0.2.10...v0.2.11
[0.2.10]: https://github.com/xlgmokha/scim-kit/compare/v0.2.9...v0.2.10
[0.2.9]: https://github.com/xlgmokha/scim-kit/compare/v0.2.8...v0.2.9
[0.2.8]: https://github.com/xlgmokha/scim-kit/compare/v0.2.7...v0.2.8
[0.2.7]: https://github.com/xlgmokha/scim-kit/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/xlgmokha/scim-kit/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/xlgmokha/scim-kit/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/xlgmokha/scim-kit/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/xlgmokha/scim-kit/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/xlgmokha/scim-kit/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/xlgmokha/scim-kit/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/xlgmokha/scim-kit/compare/v0.1.0...v0.2.0
