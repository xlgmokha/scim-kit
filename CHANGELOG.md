Version 0.6.0

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
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

[Unreleased]: https://github.com/xlgmokha/scim-kit/compare/v0.6.0...HEAD
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
