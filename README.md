# ZRO: OpenApi 3 JSON-Doc Generator for Rails

  [![Gem Version](https://badge.fury.io/rb/zero-rails_openapi.svg)](https://badge.fury.io/rb/zero-rails_openapi)
  [![Build Status](https://travis-ci.org/zhandao/zero-rails_openapi.svg?branch=master)](https://travis-ci.org/zhandao/zero-rails_openapi)
  [![Maintainability](https://api.codeclimate.com/v1/badges/471fd60f6eb7b019ceed/maintainability)](https://codeclimate.com/github/zhandao/zero-rails_openapi/maintainability)
  [![Test Coverage](https://api.codeclimate.com/v1/badges/471fd60f6eb7b019ceed/test_coverage)](https://codeclimate.com/github/zhandao/zero-rails_openapi/test_coverage)

  Concise DSL for generating OpenAPI Specification 3 (**OAS3**, formerly Swagger3) JSON documentation for Rails application.
  
  ```ruby
  class Api::ExamplesController < ApiController
    api :update, 'POST update some thing' do
      path  :id, Integer
      query :token, String, desc: 'api token', length: 16
      form data: { phone: String }
    end
  end
  ```

## Contributing

  **Hi, here is ZhanDao = ▽ =  
  It may be a very useful tool if you want to write API document clearly.  
  I'm looking forward to your issue and PR!**
  
  (Test cases are rich, like: [api DSL](spec/api_spec.rb) and [schema Obj](spec/oas_objs/schema_obj_spec.rb))

## Table of Contents

- [About OAS](#about-oas) (OpenAPI Specification)
- [Installation](#installation)
- [Configure](#configure)
- [DSL Usage](#dsl-usage)
  - [a.Basic DSL](#basic-dsl)
    - [a.1. route_base](#1-route_base-required-if-youre-not-writing-dsl-in-controller)
    - [a.2. doc_tag](#2-doc_tag-optional)
    - [a.3. components](#3-components-optional)
    - [a.4. api](#4-api-required)
    - [a.5. api_dry](#5-api_dry-optional)
  - [b. DSLs written inside `api` and `api_dry`'s block](#dsls-written-inside-api-and-api_drys-block)
    - [b.1. this_api_is_invalid!](#1-this_api_is_invalid-and-its-aliases)
    - [b.2. desc](#2-desc-description-for-the-current-api)
    - [b.3. param family methods](#3-param-family-methods-oas---parameter-object)
    - [b.4. request_body family methods](#4-request_body-family-methods-oas---request-body-object)
    - [b.5. response family methods](#5-response-family-methods-oas---response-object)
    - [b.6. callback](#6-callback-oas---callback-object)
    - [b.7. Authentication and Authorization](#7-authentication-and-authorization)
    - [b.8. server](#8-overriding-global-servers-by-server)
    - [b.9. dry](#9-dry)
  - [c. DSLs written inside `components`'s block](#dsls-written-inside-componentss-block)
  - [d. Schema and Type](#schema-and-type)
    - [d.1. (Schema) Type](#schema-type)
    - [d.2. Schema](#schema)
    - [d.3. Combined Schema](#combined-schema)
- [Run! - Generate JSON documentation file](#run---generate-json-documentation-file)
- [Use Swagger UI(very beautiful web page) to show your Documentation](#use-swagger-uivery-beautiful-web-page-to-show-your-documentation)
- [Tricks](#tricks)
    - [Write DSL somewhere else](#trick1---write-the-dsl-somewhere-else)
    - [Global DRYing](#trick2---global-drying)
    - [Auto generate description form enum](#trick3---auto-generate-description-form-enum)
    - [Skip or Use parameters define in `api_dry`](#trick4---skip-or-use-parameters-define-in-api_dry)
    - [Atuo Generate index/show Actions's Responses Based on DB Schema](#trick5---auto-generate-indexshow-actionss-response-types-based-on-db-schema)
- [Troubleshooting](#troubleshooting)
- [About `OpenApi.docs` and `OpenApi.routes_index`](#about-openapidocs-and-openapiroutes_index)

## About OAS

  Everything about OAS3 is on [OpenAPI Specification](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md)

  You can getting started from [swagger.io](https://swagger.io/docs/specification/basic-structure/)

  **I suggest you should understand the basic structure of OAS3 at least.**
  such as component (can help you reuse DSL code, when your apis are used with the
  same data structure).

## Installation

  Add this line to your Rails's Gemfile:

  ```ruby
  gem 'zero-rails_openapi'
  # or
  gem 'zero-rails_openapi', github: 'zhandao/zero-rails_openapi'
  ```

  And then execute:

      $ bundle

## Configure

  Create an initializer, configure ZRO and define your OpenApi documents.

  This is the simplest example:

  ```ruby
  # in config/initializers/open_api.rb
  require 'open_api'

  OpenApi::Config.class_eval do
    # Part 1: configs of this gem
    self.file_output_path = 'public/open_api'

    # Part 2: config (DSL) for generating OpenApi info
    open_api :doc_name, base_doc_classes: [ApiDoc]
    info version: '1.0.0', title: 'Homepage APIs'#, description: ..
    # server 'http://localhost:3000', desc: 'Internal staging server for testing'
    # bearer_auth :Authorization
  end
  ```
  
### Part 1: configs of this gem

  1. `file_output_path`(required): The location where .json doc file will be output.
  2. `default_run_dry`: defaults to run dry blocks even if the `dry` method is not called in the (Basic) DSL block. defaults to `false`.
  3. `doc_location`: give regular expressions for file or folder paths. `Dir[doc_location]` will be `require` before document generates.
      this option is only for not writing spec in controllers.
  4. `rails_routes_file`: give a txt's file path (which's content is the copy of `rails routes`'s output). This will speed up document generation. 
  5. `model_base`: The parent class of models in your application. This option is for auto loading schema from database.
  6. `file_format`

### Part 2: config (DSL) for generating OpenApi info

  See all the DSLs: [config_dsl.rb](lib/open_api/config_dsl.rb)

## DSL Usage

  There are two kinds of DSL for this gem: **basic** and **inside basic**.
  1. Basic DSLs are class methods which is for declaring your APIs, components, and spec code DRYing ...
  2. DSLs written inside the block of Basic DSLs, is for declaring the parameters, responses (and so on) of the specified API and component.

### First of all, `include OpenApi::DSL` in your base class (which is for writing spec):

  For example:
    ```ruby
    # in app/controllers/api/api_controller.rb
    class ApiController < ActionController::API
      include OpenApi::DSL
    end
    ```

### DSL Usage Example

  Here is the simplest usage:

  ```ruby
  class Api::ExamplesController < ApiController
    api :index, 'GET list' do
      query :page, Integer#, range: { ge: 1 }, default: 1
      query :rows, Integer#, desc: 'per page', range: { ge: 1 }, default: 10
    end
  end
  ```

### Basic DSL

  [source code](lib/open_api/dsl.rb)

#### (1) `route_base` [required if you're not writing DSL in controller]

  ```ruby
  # ** Method Signature
  route_base path
  # ** Usage
  route_base 'api/v1/examples'
  ```

  [Usage](#trick1---write-the-dsl-somewhere-else): write the DSL somewhere else to simplify the current controller.

#### (2) `doc_tag` [optional]

  ```ruby
  # ** Method Signature
  doc_tag name: nil, **tag_info
  # ** Usage
  doc_tag name: 'ExampleTagName', description: "ExamplesController's APIs"#, externalDocs: ...
  ```
  This method allows you to set the Tag (which is a node of [OpenApi Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#openapi-object))
  of all the APIs in the class.

  Tag's name defaults to controller_name.

#### (3) `components` [optional]

  ```ruby
  # ** Method Signature
  components(&block)
  # ** Usage
  components do
    # (block inside) DSL for defining components
    schema :DogSchema => [ { id: Integer, name: String }, dft: { id: 1, name: 'pet' } ]
    query! :UidQuery  => [ :uid, String, desc: 'uid' ]
    response :BadRqResp => [ 'bad request', :json ]
  end

  # to use component
  api :action do
    query :doge, :DogSchema # to use a Schema component
    param_ref :UidQuery     # to use a Parameter component
    response_ref :BadRqResp # to use a Response component
  end
  ```
  Each RefObj is associated with components through component key.

  We suggest that component keys should be camelized, and **must be Symbol**.

#### (4) `api` [required]

  For defining API (or we could say controller action).

  ```ruby
  # ** Method Signature
  api action_name, summary = '', id: nil, tag: nil, http: nil, dry: Config.default_run_dry, &block
  # ** Usage
  api :index, '(SUMMARY) this api blah blah ...', # block ...
  ```
  
  Parameters explanation:
  1. action_name: must be the same as controller action name
  2. id: operationId
  3. http: HTTP method (like: 'GET' or 'GET|POST')
  
#### (5) `api_dry` [optional]

  This method is for DRYing.
  The blocks passed to `api_dry` will be executed to the specified APIs which are having the actions or tags in the class.

  ```ruby
  # ** Method Signature
  api_dry action_or_tags = :all, &block
  # ** Usage
  api_dry :all, 'common response' # block ...
  api_dry :index # block ...
  api_dry :TagA # block ...

  api_dry [:index, :show] do
    query #...
  end
  ```
  
  And then you should call `dry` method ([detailed info]()) for executing the declared dry blocks:
  ```ruby
  api :index do
    dry
  end
  ```

### DSLs written inside [api](#4-api-required) and [api_dry](#5-api_dry-optional)'s block

  [source code](lib/open_api/dsl/api.rb)

  These following methods in the block describe the specified API action: description, valid?,
  parameters, request body, responses, securities and servers.

  (Here corresponds to OAS [Operation Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#operationObject))

#### (1) `this_api_is_invalid!`, and its aliases:
  ```
  this_api_is_expired!
  this_api_is_unused!
  this_api_is_under_repair!
  ```

  ```ruby
  # ** Method Signature
  this_api_is_invalid!(*)
  # ** Usage
  this_api_is_invalid! 'cause old version'
  ```

  After that, `deprecated` field of this API will be set to true.

#### (2) `desc`: description for the current API

  ```ruby
  # ** Method Signature
  desc string
  # ** Usage
  desc "current API's description"
  ```

#### (3) `param` family methods (OAS - [Parameter Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#parameterObject))

  To define parameter for APIs.
  ```
  param                              # 1. normal usage
  param_ref                          # 2. links sepcified RefObjs (by component keys) to current parameters.
  header,  path,  query,  cookie     # 3. passes specified parameter location (like header) to `param`
  header!, path!, query!, cookie!    # 4. bang method of above methods
  in_* by: { parameter_definations } # 5. batch definition, such as `in_path`, `in_query`
  examples                           # 6. examples of parameters
  ```
  **The bang method and param_name (which's name is end of a exclamation point `!`) means this param is required. Without `!` means optional. THE SAME BELOW.**

  ```ruby
  # Part 1
  # param_type:  location of parameter, like: query, path [A]
  # param_name:  name of parameter, it can be Symbol or String [B]
  # schema_type: type of parameter, like: String, Integer (must be a constant). see #schema-and-type
  # required:    :required / :req OR :optional / :opt
  # schema:      see #schema-and-type (including combined schema)
  # ** Method Signature
  param param_type, param_name, schema_type, required, schema = { }
  # ** Usage
  param :query, :page, Integer, :req,  range: { gt: 0, le: 5 }, desc: 'page number'

  # Part 2
  # ** Method Signature
  param_ref *component_key # should pass at least 1 key
  # ** Usage
  param_ref :IdPath#, :NameQuery, :TokenHeader

  # Part 3 & 4
  # ** Method Signature
  header param_name, schema_type = nil, **schema
  query! param_name, schema_type = nil, **schema
  # ** Usage
  header :'X-Token', String
  query! :readed, Boolean, default: false
  # The same effect as above, but not concise
  param :query, :readed, Boolean, :req, default: false

  # Part 5 
  # ** Method Signature
  in_query **params_and_schema
  # ** Usage
  in_query(
    search_type: String,
     search_val: String,
        export!: { type: Boolean, desc: 'export as pdf' }
  )
  # The same effect as above
  query  :search_type, String
  query  :search_val, String
  query! :export, Boolean, desc: 'export as pdf'

  # Part 6
  # ** Method Signature
  examples exp_params = :all, examples_hash
  # ** Usage
  # Suppose we have three parameters: id, name, age
  # * normal
  examples(
    right_input: [ 1, 'user', 26 ],
    wrong_input: [ 2, 'resu', 35 ]
  )
  # * using exp_params
  examples [:id, :name], {
    right_input: [ 1, 'user' ],
    wrong_input: [ 2, 'resu' ]
  }
  ```

  [A] OpenAPI 3.0 distinguishes between the following parameter types based on the parameter location: 
      **header, path, query, cookie**. [more info](https://swagger.io/docs/specification/describing-parameters/)

  [B] If `param_type` is path, for example: if the API path is `/good/:id`, you have to declare a path parameter named `id`

#### (4) `request_body` family methods (OAS - [Request Body Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#requestBodyObject))

  OpenAPI 3.0 uses the requestBody keyword to distinguish the payload from parameters.
  
  Notice: Each API has only ONE request body object. Each request body object can has multiple media types.
  It means: call `request_body` multiple times, (schemas) will be deeply merged (let's call it [fusion](#fusion)) into a request body object.
  ```
  request_body  # 1. normal usage
  body_ref      # 2. it links sepcified RefObjs (by component keys) to the body.
  body, body!   # 3. alias of request_body
  form, form!   # 4. to define a multipart/form-data request_body
  data          # 5. to define [a] property in the form-data request_body
  ```
  Bang methods(!) means the specified media-type body is required.

  ```ruby
  # Part 1
  # ** Method Signature
  # a. `data` contains the attributes (params, or properties) and their schemas required by the request body
  # b. `attr_name!` means it is required, without '!' means optional
  # c. options: desc / exp_params and examples
  # d. available `media_type` see: 
  #   https://github.com/zhandao/zero-rails_openapi/blob/master/lib/oas_objs/media_type_obj.rb#L29
  request_body required, media_type, data: { }, desc: '', **options
  # ** Usage
  request_body :opt, :form, data: {
    id!: Integer,
    name: { type: String, desc: 'name' }
  }, desc: 'a form-data'

  # Part 2
  # ** Method Signature
  body_ref component_key
  # ** Usage
  body_ref :UpdateUserBody

  # Part 3
  # ** Method Signature
  body! media_type, data: { }, **options
  # ** Usage
  body :json

  # Part 4
  # ** method Implement
  def form data:, **options # or `form!`
    body :form, data: data, **options
  end
  # ** Usage
  form! data: {
         name!: String,
      password: { type: String, pattern: /[0-9]{6,10}/ },
  }

  # Part 5
  # ** Method Signature
  data name, type = nil, schema = { }
  # ** Usage
  data :password!, String, pattern: /[0-9]{6,10}/
  ```

  <a name="fusion"></a> 
  How **fusion** works:
  1. Difference media types will be merged into `requestBody["content"]`

  ```ruby
  form data: { }
  body :json, data: { }
  # will generate: "content": { "multipart/form-data": { }, "application/json": { } }
  ```

  2. The same media-types will be deeply merged together, including their `required` array:  
     (So that you can call `form` multiple times)

  ```ruby
  data :param_a!, String
  data :param_b,  Integer
  # or same as:
  form data: { :param_a! => String }
  form data: { :param_b  => Integer }
  # will generate: { "param_a": { "type": "string" }, "param_b": { "type": "integer" } } (call it X)
  # therefore:
  #   "content": { "multipart/form-data":
  #     { "schema": { "type": "object", "properties": { X }, "required": [ "param_a" ] }
  #   }
  ```

#### (5) `response` family methods (OAS - [Response Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#response-object))

  To define the response for APIs.
  ```
  response      # 1. aliases: `resp` and `error`
  response_ref  # 2. it links sepcified RefObjs (by component keys) to the response.
  ```

  ```ruby
  # ** Method Signature
  response code, desc, media_type = nil, data: { }, **options
  # ** Usage
  resp 200, 'success', :json, data: { name: 'test' }
  response 200, 'query result', :pdf, data: File

  # ** Method Signature
  response_ref code_and_compkey_hash
  # ** Usage
  response_ref 700 => :AResp, 800 => :BResp
  ```

### (6) Callback (OAS - [Callback Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#callback-object))

  [About Callbacks](https://swagger.io/docs/specification/callbacks/)
  > In OpenAPI 3 specs, you can define callbacks – asynchronous, out-of-band requests that your service will send to some other service in response to certain events. This helps you improve the workflow your API offers to clients.  
    A typical example of a callback is a subscription functionality ... you can define the format of the “subscription” operation as well as the format of callback messages and expected responses to these messages.  
    This description will simplify communication between different servers and will help you standardize use of webhooks in your API.  
  [Complete YAML Example](https://github.com/OAI/OpenAPI-Specification/blob/master/examples/v3.0/callback-example.yaml)
  
  The structure of Callback Object:
  ```
  callbacks:
    Event1:
      path1:
        ...
      path2:
       ...
    Event2:
      ...
  ```
  
  `callback` method is for defining callbacks.
  ```ruby
  # ** Method Signature
  callback event_name, http_method, callback_url, &block
  # ** Usage
  callback :myEvent, :post, 'localhost:3000/api/goods' do
    query :name, String
    data :token, String
    response 200, 'success', :json, data: { name: String, description: String }
  end
  ```
  
  Use runtime expressions in callback_url:
  ```ruby
  callback :myEvent, :post, '{body callback_addr}/api/goods/{query id}'
  # the final URL will be: {$request.body#/callback_addr}/api/goods/{$request.query.id}
  # Note: Other expressions outside "$request" are not supported yet
  ```

#### (7) Authentication and Authorization

  First of all, please make sure that you have read one of the following documents:
  [OpenApi Auth](https://swagger.io/docs/specification/authentication/)
  or [securitySchemeObject](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securitySchemeObject)

  ##### Define Security Scheme

  Use these DSL **in your initializer config or `components` block**:
  ```
  security_scheme # alias `auth_scheme`
  base_auth       # will call `security_scheme`
  bearer_auth     # will call `security_scheme`
  api_key         # will call `security_scheme`
  ```
  It's very simple to use (if you understand the above document)
  ```ruby
  # ** Method Signature
  security_scheme scheme_name, other_info
  # ** Usage
  security_scheme :BasicAuth, { type: 'http', scheme: 'basic', desc: 'basic auth' }

  # ** Method Signature
  base_auth scheme_name, other_info = { }
  bearer_auth scheme_name, format = 'JWT', other_info = { }
  api_key scheme_name, field:, in:, **other_info
  # ** Usage
  base_auth :BasicAuth, desc: 'basic auth' # the same effect as above
  bearer_auth :Token
  api_key :ApiKeyAuth, field: 'X-API-Key', in: 'header', desc: 'pass api key to header'
  ```

  ##### Apply Security

  ```
  # Use in initializer (Global effectiveness)
  global_security_require # alias: global_security & global_auth

  # Use in `api`'s block (Only valid for the current controller)
  security_require # alias security & auth_with
  ```
  ```ruby
  # ** Method Signature
  security_require scheme_name, scopes: [ ]
  # ** Usage
  global_auth :Token
  auth_with   :OAuth, scopes: %w[ read_example admin ]
  ```

#### (8) Overriding Global Servers by `server`

  ```ruby
  # ** Method Signature
  server url, desc: ''
  # ** Usage
  server 'http://localhost:3000', desc: 'local'
  ```
  
#### (9) `dry`

  You have to call `dry` method inside `api` block, or pass `dry: true` as parameter of `api`,
  for executing the dry blocks you declared before. Otherwise nothing will happen.
  
  ```ruby
  # ** Method Signature
  dry only: nil, skip: nil, none: false
  
  # ** Usage
  # In general, just:
  dry
  # To skip some params declared in dry blocks:
  dry skip: [:id, :name]
  # `only` is used to specify which parameters will be taken from dry blocks
  dry only: [:id]
  ```

### DSLs written inside [components](#3-components-optional)'s block
  [code source](lib/open_api/dsl/components.rb) (Here corresponds to OAS [Components Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#componentsObject))

  Inside `components`'s block,
  you can use the same DSLs as [DSLs written inside `api` and `api_dry`'s block](#dsls-written-inside-api-and-api_drys-block).  
  But notice there are two differences:

  (1) Each method needs to pass one more parameter `component_key` (as the first parameter),
      it will be used as the reference name for the component.

  ```ruby
  query! :UidQuery, :uid, String， desc: 'it is a component'
  #         ↑         ↑
  # component_key  param_name
  
  # You can also use "arrow writing", it may be easier to understand
  query! :UidQuery => [:uid, String, desc: '']
  ```

  (2) You can use `schema` to define a Schema Component.

  ```ruby
  # ** Method Signature
  schema component_key, type = nil, **schema
  # ** Usage
  schema :Dog  => [ String, desc: 'doge' ]
  # advance usage
  schema :Dog => [
      {
           id!: Integer,
          name: { type: String, desc: 'doge name' }
      }, default: { id: 1, name: 'pet' }
  ]
  # or flatten writing
  schema :Dog, { id!: Integer, name: String }, default: { id: 1, name: 'pet' }
  #
  # pass a ActiveRecord class constant as `component_key`,
  #   it will automatically load schema from database and then generate the component.
  schema User # easy! And the component_key will be :User
  ```
  To enable load schema from database, you must set [model base](#part-1-configs-of-this-gem) correctly.
  
### Schema and Type

  schema and type -- contain each other

#### (Schema) Type

  Support all [data types](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#dataTypes) in OAS.   

  1. String / 'binary' / 'base64' / 'uri'
  2. Integer / Long / 'int32' / 'int64' / Float / Double
  3. File (it will be converted to `{ type: 'string', format: Config.file_format }`)
  4. Date / DateTime
  5. 'boolean'
  6. Array / Array[\<Type\>] (like: `Array[String]`, `[String]`)
  7. Nested Array (like: `[[[Integer]]]`)
  8. Object / Hash (Object with properties)  
     Example: `{ id!: Integer, name: String }`
  9. Nested Hash: `{ id!: Integer, name: { first: String, last: String } }`
  10. Nested Array[Nested Hash]: `[[{ id!: Integer, name: { first: String, last: String } }]]`
  11. Symbol Value: it will generate a Schema Reference Object link to the component correspond to ComponentKey, like: :IdPath, :NameQuery
  
  **Notice** that Symbol is not allowed in all cases except 11.
  
#### Schema

  [OAS Schema Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#schemaObject)
  and [source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/oas_objs/schema_obj.rb)
  
  Schema (Hash) is for defining properties of parameters, responses and request bodies.
  
  The following property keys will be process slightly:
  1. desc / description / d
  2. enum / in / values / allowable_values  
     should be Array or Range
  3. range: allow value in this continuous range  
     should be Range or like `{ gt: 0, le: 5 }`
  4. length / size / lth  
     should be an Integer, Integer Array, Integer Range, 
     or the following format Symbol: `:gt_`, `:ge_`, `:lt_`, `:le_` (:ge_5 means "greater than or equal 5"; :lt_9 means "lower than 9")
  5. pattern / regxp
  6. additional_properties / add_prop / values_type
  7. example
  8. examples
  9. format
  10. default: default value
  11. type

  The other keys will be directly merged. Such as:
  1. `title: 'Property Title'`
  2. `myCustomKey: 'Value'`

#### Combined Schema

  Very easy to use:
  ```ruby
  query :combination, one_of: [ :GoodSchema, String, { type: Integer, desc: 'integer input' } ]

  form data: {
      :combination_in_form => { any_of: [ Integer, String ] }
  }

  schema :PetSchema => [ not: [ Integer, Boolean ] ]
  ```

  OAS: [link1](https://swagger.io/docs/specification/data-models/oneof-anyof-allof-not/),
  [link2](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#schemaObject)

## Run! - Generate JSON Documentation File

  Use `OpenApi.write_docs`:

  ```ruby
  OpenApi.write_docs# if: !Rails.env.production?
  ```

  `if` option is used to control whether a JSON document is generated or not.
  
  Then the JSON files will be written to the directories you set. (Each API a file.)

## Use Swagger UI(very beautiful web page) to show your Documentation

  Download [Swagger UI](https://github.com/swagger-api/swagger-ui) (version >= 2.3.0 support the OAS3)
  to your project,
  change the default JSON file path(url) in index.html.
  In order to use it, you may have to enable CORS, [see](https://github.com/swagger-api/swagger-ui#cors-support)

## Tricks

### Trick1 - Write the DSL Somewhere Else

  Does your documentation take too many lines?  
  Do you want to separate documentation from controller to simplify both?  
  Very easy! Just follow

  ```ruby
  # config/initializers/open_api.rb
  # in your configuration
  base_doc_classes: [ApiDoc]

  # app/api_doc/api_doc.rb
  require 'open_api/dsl'

  class ApiDoc < Object
    include OpenApi::DSL
  end

  # app/api_doc/v1/examples_doc.rb
  class V1::ExamplesDoc < ApiDoc
    route_base 'api/v1/examples'

    api :index do
      # ...
    end
  end
  ```

  Explain: These four steps are necessary:
  1. create a class, like ApiDoc, and make it include OpenApi::DSL (then it could be the base class for writing Api spec).
  2. set the specified Api spec's base_doc_classes to ApiDoc.
  3. let your doc class (like V1::ExamplesDoc) inherit the base_doc_classes (ApiDoc).
  4. set the route_base (to route path api/v1/examples of that controller Api::V1::ExamplesController) inside V1::ExamplesDoc.
  
  Notes: file name ends in `_doc.rb` by default, but you can change it by setting `Config.doc_location`
    (it should be file paths, defaults to `./app/**/*_doc.rb`).

### Trick2 - Global DRYing

  Method `api_dry` is for DRY but its scope is limited to the current controller.

  I have no idea of best practices, But you can look at this [file](examples/auto_gen_doc.rb).  
  The implementation of the file is: do `api_dry` when inherits the base controller inside `inherited` method.

  You can use `sort` to specify the order of parameters.

### Trick3 - Auto Generate Description from Enum

  Just use `enum!`:
  ```ruby
  query :search_type, String, desc: 'search field, allows：<br/>', enum!: %w[name creator category price]
  # it will generate: 
  "search field, allows：<br/>1/ name<br/>2/ creator,<br/>3/ category<br/>4/ price<br/>"
  ```
  Or Hash `enum!`:
  ```ruby
  query :view, String, desc: 'allows values<br/>', enum!: {
          'all goods (default)': :all,
                  'only online': :online,
                 'only offline': :offline,
              'expensive goods': :get,
                  'cheap goods': :borrow,
  }
  ```

## Troubleshooting

- **You wrote document of the current API, but not find in the generated json file?**  
  Check your routing settings.

- **Report error when require `routes.rb`?***
  1. Run `rails routes`.
  2. Copy the output to a file, for example `config/routes.txt`.
     Ignore the file `config/routes.txt`.
  3. Put `c.rails_routes_file = 'config/routes.txt'` to your ZRO config.


## About `OpenApi.docs` and `OpenApi.routes_index`

  After `OpenApi.write_docs`, the above two module variables will be generated.

  `OpenApi.docs`: A Hash with API names as keys, and documents of each APIs as values.  
  documents are instances of ActiveSupport::HashWithIndifferentAccess.

  `OpenApi.routes_index`: Inverted index of controller path to API name mappings.  
  Like: `{ 'api/v1/examples' => :homepage_api }`  
  It's useful when you want to look up a document based on a controller and do something.

## Development

  After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

  To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

  The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

  Everyone interacting in the Zero-RailsOpenApi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
