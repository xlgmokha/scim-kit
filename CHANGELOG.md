Version 0.5.0

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- nil

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

[Unreleased]: https://github.com/mokhan/scim-kit/compare/v0.5.0...HEAD
[0.4.0]: https://github.com/mokhan/scim-kit/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/mokhan/scim-kit/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/mokhan/scim-kit/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/mokhan/scim-kit/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/mokhan/scim-kit/compare/v0.2.16...v0.3.0
[0.2.16]: https://github.com/mokhan/scim-kit/compare/v0.2.15...v0.2.16
[0.2.15]: https://github.com/mokhan/scim-kit/compare/v0.2.14...v0.2.15
[0.2.14]: https://github.com/mokhan/scim-kit/compare/v0.2.13...v0.2.14
[0.2.13]: https://github.com/mokhan/scim-kit/compare/v0.2.12...v0.2.13
[0.2.12]: https://github.com/mokhan/scim-kit/compare/v0.2.11...v0.2.12
[0.2.11]: https://github.com/mokhan/scim-kit/compare/v0.2.10...v0.2.11
[0.2.10]: https://github.com/mokhan/scim-kit/compare/v0.2.9...v0.2.10
[0.2.9]: https://github.com/mokhan/scim-kit/compare/v0.2.8...v0.2.9
[0.2.8]: https://github.com/mokhan/scim-kit/compare/v0.2.7...v0.2.8
[0.2.7]: https://github.com/mokhan/scim-kit/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/mokhan/scim-kit/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/mokhan/scim-kit/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/mokhan/scim-kit/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/mokhan/scim-kit/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/mokhan/scim-kit/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/mokhan/scim-kit/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/mokhan/scim-kit/compare/v0.1.0...v0.2.0
