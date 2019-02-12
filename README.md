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
- [Usage - DSL](#usage---dsl)
  - [Basic DSL](#basic-dsl)
    - [route_base](#1-route_base-required-if-youre-not-writing-dsl-in-controller)
    - [doc_tag](#2-doc_tag-optional)
    - [components](#3-components-optional)
    - [api](#4-api-required)
    - [api_dry](#5-api_dry-optional)
  - [DSLs written inside `api` and `api_dry`'s block](#dsl-methods-inside-api-and-api_drys-block)
    - [this_api_is_invalid!](#1-this_api_is_invalid-and-its-aliases)
    - [desc](#2-desc-description-for-the-current-api)
    - [param family methods](#3-param-family-methods-oas---parameter-object)
    - [request_body family methods](#4-request_body-family-methods-oas---request-body-object)
    - [response family methods](#5-response-family-methods-oas---response-object)
    - [callback](#6-callback-oas---callback-object)
    - [Authentication and Authorization](#7-authentication-and-authorization)
    - [server](#8-overriding-global-servers-by-server)
  - [DSLs written inside `components`'s block](#dsl-methods-inside-componentss-block-code-source)
  - [Schema and Type](#schema-and-type)
- [Run! - Generate JSON documentation file](#run---generate-json-documentation-file)
- [Use Swagger UI(very beautiful web page) to show your Documentation](#use-swagger-uivery-beautiful-web-page-to-show-your-documentation)
- [Tricks](#tricks)
    - [Write DSL somewhere else](#trick1---write-the-dsl-somewhere-else)
    - [Global DRYing](#trick2---global-drying)
    - [Auto generate description](#trick3---auto-generate-description)
    - [Skip or Use parameters define in `api_dry`](#trick4---skip-or-use-parameters-define-in-api_dry)
    - [Atuo Generate index/show Actions's Responses Based on DB Schema](#trick5---auto-generate-indexshow-actionss-response-types-based-on-db-schema)
    - [Combined Schema (one_of / all_of / any_of / not)](#trick6---combined-schema-one_of--all_of--any_of--not)
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
  ```
  request_body
  body_ref      # for reuse component,
                #   it links sepcified RefObjs (by component keys) to current body.
  body, body!   # alias of request_body
  form, form!   # define a multipart/form-data body
  data          # define [a] property in the form-data body
  file, file!   # define a File media-type body
  ```
  Bang methods(!) means the specified media-type body is required.

  ```ruby
  # ** Method Signature
  request_body(required, media_type, data: { }, **options)
  # ** Usage
  # (1) `data` contains all the attributes required by this request body.
  # (2) `param_name!` means it is required, otherwise without '!' means optional.
  request_body :opt, :form, data: { id!: Integer, name: { type: String, desc: 'name' } }, desc: 'form-data'


  # ** Method Signature
  body_ref(component_key)
  # ** Usage
  body_ref :UpdateDogeBody


  # ** Method Signature
  body!(media_type, data: { }, **options)
  # ** Usage
  body :json


  # method implement
  def form data:, **options
    body :form, data: data, **options
  end
  # ** Usage
  form! data: {
      name: String,
      password: String,
      password_confirmation: String
  }
  # advance usage
  form data: {
          :name! => { type: String, desc: 'user name' },
      :password! => { type: String, pattern: /[0-9]{6,10}/, desc: 'password' },
      # optional
        :remarks => { type: String, desc: 'remarks' },
  }, exp_by:            %i[ name password ],
     examples: {         #    ↓        ↓
         :right_input => [ 'user1', '123456' ],
         :wrong_input => [ 'user2', 'abc'    ]
     },
  desc: 'for creating a user'


  # method implement
  def data name, type = nil, schema_info = { }
    schema_info[:type] = type if type.present?
    form data: { name => schema_info }
  end
  # ** Usage: please look at the 4th point below

  # about `file`
  def file! media_type, data: { type: File }, **options
    body! media_type, data: data, **options
  end
  ```

  1. `media_type`: we provide some [mapping](lib/oas_objs/media_type_obj.rb) from symbols to real media-types.
  2. `schema_info`: as above (see param).
  3. `exp_by` and `examples`: for the above example, the following has the same effect:
     ```
     examples: {
         :right_input => { name: 'user1', password: '123456' },
         :wrong_input => { name: 'user2', password: 'abc' }
     }
     ```
  4. *[IMPORTANT]* Each request bodies you declared will **FUSION** together. <a name="fusion"></a>  
     (1) Media-Types will be merged to `requestBody["content"]`
     ```ruby
     form data: { }, desc: 'desc'
     body :json, data: { }, desc: 'desc'
     # will generate: "content": { "multipart/form-data": { }, "application/json": { } }
     ```
     (2) The same media-types will fusion, but not merge:  
         (So that you can write `form` separately, and make `data` method possible.)
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

  Define the responses for the API (action).
  ```
  response      # aliases: `resp` and `error`
  response_ref
  ```

  ```ruby
  # ** Method Signature
  response(code, desc, media_type = nil, data: { }, type: nil)
  # ** Usage
  resp 200, 'json response', :json, data: { name: 'test' }
  response 200, 'query result', :pdf, type: File
  # same as:
  response 200, 'query result', :pdf, data: File

  # ** Method Signature
  response_ref(code_compkey_hash)
  # ** Usage
  response_ref 700 => :AResp, 800 => :BResp
  ```

  **practice:** Automatically generate responses based on the agreed error class. [AutoGenDoc](examples/auto_gen_doc.rb#L63)
  
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
  
  To define callbacks, you can use `callback` method:
  ```ruby
  # ** Method Signature
  callback(event_name, http_method, callback_url, &block)
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

  Use these DSL in your initializer or `components` block:
  ```
  security_scheme # alias `auth_scheme`
  base_auth       # will call `security_scheme`
  bearer_auth     # will call `security_scheme`
  api_key         # will call `security_scheme`
  ```
  It's very simple to use (if you understand the above document)
  ```ruby
  # ** Method Signature
  security_scheme(scheme_name, other_info)
  # ** Usage
  security_scheme :BasicAuth, { type: 'http', scheme: 'basic', desc: 'basic auth' }

  # ** Method Signature
  base_auth(scheme_name, other_info = { })
  bearer_auth(scheme_name, format = 'JWT', other_info = { })
  api_key(scheme_name, field:, in:, **other_info)
  # ** Usage
  base_auth :BasicAuth, desc: 'basic auth' # the same effect as ↑↑↑
  bearer_auth :Token
  api_key :ApiKeyAuth, field: 'X-API-Key', in: 'header', desc: 'pass api key to header'
  ```

  ##### Apply Security

  ```
  # In initializer
  # Global effectiveness
  global_security_require
  global_security # alias
  global_auth     # alias

  # In `api`'s block
  # Only valid for the current controller
  security_require
  security  # alias
  auth      # alias
  need_auth # alias
  ```
  Name is different, signature and usage is similar.
  ```ruby
  # ** Method Signature
  security_require(scheme_name, scopes: [ ])
  # ** Usage
  global_auth :Token
  need_auth   :Token
  auth :OAuth, scopes: %w[ read_example admin ]
  ```

#### (8) Overriding Global Servers by `server`

  ```ruby
  # ** Method Signature
  server(url, desc: '')
  # ** Usage
  server 'http://localhost:3000', desc: 'local'
  ```

### DSLs written inside [components]()'s block ([code source](lib/open_api/dsl/components.rb))

  (Here corresponds to OAS [Components Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#componentsObject))

  Inside `components`'s block,
  you can use the same DSL as [[DSL methods inside `api` and `api_dry`'s block]](#dsl-methods-inside-api-and-api_drys-block).
  But there are two differences:

  (1) Each method needs to pass one more parameter `component_key`
    (in the first parameter position),
    this will be used as the reference name for the component.

  ```ruby
  query! :UidQuery, :uid, String
  ```
  This writing is feasible but not recommended,
  because component's key and parameter's name seem easy to confuse.
  The recommended writing is:

  ```ruby
  query! :UidQuery => [:uid, String]
  ```

  (2) You can use `schema` to define a Schema Component.

  ```ruby
  # ** Method Signature
  schema(component_key, type = nil, **schema_info)
  # ** Usage
  schema :Dog  => [ String, desc: 'dogee' ] # <= schema_type is `String`
  # advance usage
  schema :Dog => [
      {
          id!: Integer,
          name: { type: String, must_be: 'name', desc: 'name' }
      }, # <= this hash is schema type[1]
      dft: { id: 1, name: 'pet' },
      desc: 'dogee'
  ]
  # or (unrecommended)
  schema :Dog, { id!: Integer, name: String }, dft: { id: 1, name: 'pet' }, desc: 'dogee'
  #
  # pass a ActiveRecord class constant as `component_key`,
  #   it will automatically read the db schema to generate the component.
  schema User # easy! And the component_key will be :User
  ```
  [1] see: [Type](#schema-and-type)
  
### Schema and Type

```ruby
# When schema_type is a Object
  #   (describe by hash, key means prop's name, value means prop's schema_type)
  query :good, { name: String, price: Float, spec: { size: String, weight: Integer } }, desc: 'good info'
  # Or you can use `type:` to sign the schema_type, maybe this is clearer for describing object
  query :good, type: { name: String, price: Float, spec: { size: String, weight: Integer } }, desc: 'good info'
  #
  query :good_name, type: String # It's also OK, but some superfluous
  query :good_name, String       # recommended
  # About Combined Schema (`one_of` ..), see the link below.
```

## Run! - Generate JSON Documentation File

  Use `OpenApi.write_docs`:

  ```ruby
  # initializer
  OpenApi.write_docs generate_files: !Rails.env.production?

  # or run directly in console
  OpenApi.write_docs # will generate json doc files
  ```

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

### Trick3 - Auto Generate Description

  ```ruby
  desc 'api desc',
       search_type!: 'search field, allows：<br/>'
  query :search_type, String, enum: %w[name creator category price]

  # or

  query :search_type, String, desc!: 'search field, allows：<br/>',
        enum: %w[name creator category price]
  ```

  Notice `!` use (`search_type!`, `desc!`), it tells ZRO to append
  information that analyzed from definitions (enum, must_be ..) to description automatically.

  Any one of above will generate:
  > search field, allows：<br/>1/ name<br/>2/ creator,<br/>3/ category<br/>4/ price<br/>

  You can also use Hash to define `enum`:
  ```ruby
  query :view, String, desc: 'allows values<br/>', enum!: {
          'all goods (default)': :all,
                  'only online': :online,
                 'only offline': :offline,
              'expensive goods': :get,
                  'cheap goods': :borrow,
  }
  ```
  Read this [file](examples/auto_gen_desc.rb) to learn more.

### Trick4 - Skip or Use parameters define in api_dry

  Pass `skip: []` and `use: []` to `api` like following code:
  ```ruby
  api :index, 'desc', skip: [ :Token ]
  ```

  Look at this [file](examples/goods_doc.rb) to learn more.

### Trick5 - Auto Generate index/show Actions's Response-Types Based on DB Schema

  Use method `load_schema` in `api_dry`.

  See this [file](examples/auto_gen_doc.rb#L51) for uasge information.

### Trick6 - Combined Schema (one_of / all_of / any_of / not)

  ```ruby
  query :combination, one_of: [ :GoodSchema, String, { type: Integer, desc: 'integer input' } ]

  form data: {
      :combination_in_form => { any_of: [ Integer, String ] }
  }

  schema :PetSchema => [ not: [ Integer, Boolean ] ]
  ```

  OAS: [link1](https://swagger.io/docs/specification/data-models/oneof-anyof-allof-not/),
  [link2](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#schemaObject)

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
