# Version Changelog

## [Unreleased]

## [2.1.5] - 2020/9/20 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v2.1.4...v2.1.5)

### Fixed

1. Keyword arguments in Ruby 2.7 [issued by @dandunckelman](https://github.com/zhandao/zero-rails_openapi/issues/66)

## [2.1.3 - 2.1.4] - 2020/2/10 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v2.1.2...v2.1.4)

### Fixed

1. Fix response HTTP Status Code's type, restrict to String [issued by @am17torres](https://github.com/zhandao/zero-rails_openapi/issues/60)

### Added

1. Configurable additionalProperties's default value of Object type [issued by @remuspoienar](https://github.com/zhandao/zero-rails_openapi/issues/61)

## [2.1.1 - 2.1.2] - 2019/2/12 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v2.1.0...v2.1.2)

### Fixed

1. Fix response header schema output [PR #49 by @drjonnicholson](https://github.com/zhandao/zero-rails_openapi/pull/49)
2. Fix router formatter in Rails 6 [PR #53 by @rjayroach](https://github.com/zhandao/zero-rails_openapi/pull/53)
3. Support for generating `additional_properties: true` [issued by @bopm](https://github.com/zhandao/zero-rails_openapi/issues/55)

## [2.1.0] - 2019/2/16 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v2.0.3...v2.1.0)

See: [PR #43](https://github.com/zhandao/zero-rails_openapi/pull/43)

### Added

Headers in Response Object ([issued by @drjonnicholson](https://github.com/zhandao/zero-rails_openapi/issues/42))

## [2.0.0 - 2.0.3] - 2019/2/12 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.7.0...v2.0.3)

See: [PR #35](https://github.com/zhandao/zero-rails_openapi/pull/35)

1. Totally refactoring
2. README rewritten
3. Removed Or Changed uncommonly used features

## [1.7.0] - 2018/12/17 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.6.1...v1.7.0)

### Added

1. Declare Ruby & Rails version requirement in Gemspec

### Fixed

1. `match?` => `'string'[matcher].present?`, for compatibility with ruby < 2.4

### Changed

1. Config option `base_doc_class: ApiDoc` changed to `base_doc_classes: [ApiDoc]`

## [1.6.1] - 2018/8/21 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.6.0...v1.6.1)

### Added

`tag` is allowed to pass to `api`

### Fixed

1. camelize action tag
2. update gems cause sprockets vulnerability

## [1.6.0] - 2018/6/26 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.9...v1.6.0)

### Changed

1. issue [#21](https://github.com/zhandao/zero-rails_openapi/issues/21) support additionalProperties. Thanks @barnaclebarnes
2. issue [#23](https://github.com/zhandao/zero-rails_openapi/issues/23) Uniqueness of operationId. Thanks @barnaclebarnes

### Fixed

1. issue [#22](https://github.com/zhandao/zero-rails_openapi/issues/22) missing `/` in reference. Thanks @barnaclebarnes

## [1.5.8 & 1.5.9] - 2018/6/19 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.7...v1.5.9)

### Changed

1. issue [#17](https://github.com/zhandao/zero-rails_openapi/issues/17) singular example in schema. Thanks @williamdias
1. issue [#18](https://github.com/zhandao/zero-rails_openapi/issues/18) define multiple components blocks in one class. Thanks @Amnesthesia

## [1.5.7] - 2018/4/6 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.6...v1.5.7)

### Changed

1. issue [#16](https://github.com/zhandao/zero-rails_openapi/issues/16) DSL in `base_doc_class` can not be generated. Thanks @jonathantribouharet

### Fixed

1. issue [#15](https://github.com/zhandao/zero-rails_openapi/issues/15) colorize was not required. Thanks @jonathantribouharet
2. securitySchemes defined by config DSL was not be generated.

## [1.5.6] - 2018/3/23 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.5...v1.5.6)

### Changed

1. Upgrade `loofah` and `rails-html-sanitizer` cause XSS vulnerability.
2. Refactor and document DSL for Rspec (spec_dsl.rb).

## [1.5.5] - 2018/2/21 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.4...v1.5.5)

### Added

1. Callback Object has been supported. (issue [#12](#https://github.com/zhandao/zero-rails_openapi/issues/12) @austbot)

### Changed

1. `mk`'s parameter `eq` is changed to `get`. (dssl.rb)

## [1.5.4] - 2018/2/15 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.3...v1.5.4)

Thanks to @austbot, fix - colorize fails at runtime.

## [1.5.3] - 2018/1/25 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.2...v1.5.3)

### Added

1. Colorize output.

### Changed

1. Refactoring SchemaObj and remove `preprocess`.
2. `schema_hash` => `schema_info`.
3. Refactoring `process_objs` .. dsl/ files.

### Fixed

1. max lth and min lth is reversed.

## [1.5.2] - 2018/1/2 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.5.1...v1.5.2)

### Added

1. `do_*` can be passed common schema after (or before) `by:`.
2. when this action can be accessed through multiple HTTP methods (but not set through `match`),
   it also matches and generate both HTTP methods.

### Changed

1. `root_controller` => `base_doc_class`.
2. `ctrl_path` => `ctrl_base`.
3. `apis_tag` => `doc_tag`.
4. `@_ctrl_infos` => `@doc_info`, `@_api_infos` => `@api_info`, `@_apis_dry_blocks` => `@zro_dry_blocks`.
5. `OpenApi.paths_index` => `OpenApi.routes_index`.
6. `get_actions_by_ctrl_path` => `get_actions_by_route_base`.
7. `Config.dft_file_format` => `Config.file_format`.
8. Modify the description of the test case (remove `should`).
9. `deep_merge!` instead of `_fusion`.
10. `ApiInfoObj` => `ApiInfo`.

## [1.5.1 - 100% Test Coverage] - 2017/12/21 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.4.3...v1.5.1)

### Completed the test code (250+ examples), and make it 100% coverage.

### Feature

1. `type: [String, Integer ..]` will generate an array, which's items
   would be a oneOf combined schema.

### Fixed:

1. `desc` will override dry's.
2. `type: something` is passed to `schema_hash`,  but not `type`.
3. Should not `skip` the params inside block.
4. `body_ref` invalid.
5. schema `length`'s order is reversed.
6. Example Obj ref.

### Added:

1. Use `simplecov`.
2. CodeClimate test hook.
3. Test's support.
4. Designed RSpec matchers `have_keys` and `have_size`.
5. Designed a set of RSpec's DSL (DSSL) for testing.

### Changed:

1. WILL NOT do `recognize_is_options_in`.
2. `instance_eval` => `instance_exec` in dsl.rb.
3. Guard Clause for `generate_docs` and where schema could be defined.
4. Change signature of `server` in `api`.
5. Simplify `recursive`s.
6. `enum: { 'desc' => :enum1 }` => `enum!: { 'desc' => :enum1 }`

## [1.4.2 & 1.4.3] - 2017/12/11&13 - [view diff](https://github.com/zhandao/zero-rails_openapi/compare/v1.4.1...v1.4.3)

### Feature

1. `example` method in `components` block.
2. Request Body (also Response):
    1. The same media-types will be fusion together.  
       (This means you can write `form` separately.)
    2. Different media-types will not be replaced, all will be merged in `content`.
    3. Support flat statement form-data by `data`.

### Fixed

1. `generate_doc` raise 'should not nil when merge' if settings[:components] not set.
2. `@preprocessed not initialize` warning.

### Added

1. Schema option `blankable`.
2. Schema option alias `in` to `enum`.
3. Schema option `pattern` could be `String` for supporting Time Format.

### Changed

1. `form` mandatory requirements pass `data: { }`.
2. Remove `request_body`'s parameter `desc` to `**options`.
3. Remove aliases of `response`.

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
