# Version Changelog

## [1.4.2 & Unreleased] - 2017/12/11&12 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.4.1...v1.4.3)

### Feature

1. `example` method in `components` block.
2. Request Body (also Response):
    1. The same media-types will be fusion together.  
       (This means you can write `form` separately.)
    2. Different media-types will not be replaced, all will be in `content`.
    3. Support flat statement `form`.

### Fixed

1. `generate_doc` raise 'should not nil when merge' if settings[:components] not set.
2. `@preprocessed not initialize` warning.

### Added

1. Schema option `blankable`.
2. Schema option alias `in` to `enum`.
3. Schema option `pattern` could be `String` for supporting Time Format.

## [1.4.1] - 2017/12/6 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.4.0...v1.4.1)

### Feature

1. Pass a ActiveRecord class constant to the `schema`, 
   it will automatically read the db schema to generate the component.

### Fixed

1. Fix: Components defined in the controller overwrite the ones defined in the configuration.

### Changed

1. Remove JBuilder automatic generator.
2. Refactoring based on CodeClimate.
3. Rename `CtrlInfoObj` to `Components`.

### Added

1. Update README.
2. Add CHANGELOG.
3. `doc_location` can be configured.

## [1.4.0] - 2017/12/3 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.3.3...v1.4.0)

### Fixed

1. Fix controller's require question in `generate_docs`.

### Feature

1. Support CombinedSchema, like `one_of`, `any_of`..
2. Authentication and Authorization DSL, for Defining Security Scheme and Applying Security.
3. The ability to identify multi HTTP verbs.
4. Support read files to get routes information. (Config.rails_routes_file)

### Changed

1. **[IMPORTANT]** DSL `open_api` => `api`.
2. Config.register_docs => Config.open_api_docs.
3. Document Definition DSL `api` => `open_api`.
4. Use module instance variables instead of global variables.
5. Is refactoring based on `rubocop` by hand.

### Added

1. Also support `api :name, type: String`.
   (You have to write this before `api :name, String`)
2. Support designated http method in `api`.
3. The completion of the basic README.

## [1.3.2 & 1.3.3] - 2017/11/10&21 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.3.1...v1.3.3)

### Feature

1. Document Definition DSL.
2. Parameter `order`: 
   Support to use `sort` to specify the order in which parameters are arranged.
   This is useful when you dry your DSL.
3. Parameter `examples`.

### Added

1. Rewrote README.

## [1.3.1] - 2017/11/5 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.3.0...v1.3.1)

1. Refactoring based on bbatsov and Airbnb's style guide, more readable.
2. Support response override by using `override_response`.
3. Separate `apis_set` into `apis_tag` and `components`.
4. Support simplify param DSL with `do_* by: { }` method.
