# ZRO: OpenApi 3 JSON-Doc Generator for Rails

  [![Gem Version](https://badge.fury.io/rb/zero-rails_openapi.svg)](https://badge.fury.io/rb/zero-rails_openapi)
  [![Build Status](https://travis-ci.org/zhandao/zero-rails_openapi.svg?branch=master)](https://travis-ci.org/zhandao/zero-rails_openapi)
  [![Maintainability](https://api.codeclimate.com/v1/badges/471fd60f6eb7b019ceed/maintainability)](https://codeclimate.com/github/zhandao/zero-rails_openapi/maintainability)
  [![Gitter Chat](https://badges.gitter.im/zero-rails_openapi/Lobby.svg)](https://gitter.im/zero-rails_openapi/Lobby)
  
  Concise DSL for generating OpenAPI Specification 3 (**OAS3**, formerly Swagger3) JSON documentation for Rails application, 
  then you can use Swagger UI 3.2.0+ to show the documentation.

## Contributing

  **Hi, here is ZhanDao = ▽ =  
  I think it's a very useful tool when you want to write API document clearly.  
  I'm looking forward to your issue and PR, thanks!**

## Table of Contents

- [About OAS](#about-oas) (OpenAPI Specification)
- [Installation](#installation)
- [Configure](#configure)
- [Usage - DSL](#usage---dsl)
  - [DSL methods inside `api` and `api_dry`'s block](#dsl-methods-inside-api-and-api_drys-block)
  - [DSL methods inside `components`'s block](#dsl-methods-inside-componentss-block-code-source)
- [Usage - Generate JSON documentation file](#usage---generate-json-documentation-file)
- [Usage - Use Swagger UI(very beautiful web page) to show your Documentation](#usage---use-swagger-uivery-beautiful-web-page-to-show-your-documentation)
- [Tricks](#tricks)
    - [Write DSL somewhere else](#trick1---write-the-dsl-somewhere-else)
    - [Global DRYing](#trick2---global-drying)
    - [Auto generate description](#trick3---auto-generate-description)
    - [Skip or Use parameters define in `api_dry`](#trick4---skip-or-use-parameters-define-in-api_dry)
    - [Atuo Generate index/show Actions's Responses Based on DB Schema](#trick5---auto-generate-indexshow-actionss-response-types-based-on-db-schema)
    - [Combined Schema (one_of / all_of / any_of / not)](#trick6---combined-schema-one_of--all_of--any_of--not)
- [Troubleshooting](#troubleshooting)
- [About `OpenApi.docs` and `OpenApi.paths_index`](#about-openapidocs-and-openapipaths_index)

## About OAS

  Everything about OAS3 is on [OpenAPI Specification](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md)
  
  You can getting started from [swagger.io](https://swagger.io/docs/specification/basic-structure/)
  
  **I suggest you should understand OAS3's basic structure at least.**
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
  
  Or install it yourself as:
  
      $ gem install zero-rails_openapi
    
## Configure

  Create an initializer, configure ZRO and define your OpenApi documents.
  
  This is the simplest example:
  
  ```ruby
  # config/initializers/open_api.rb
  require 'open_api'
  
  OpenApi::Config.tap do |c|
    # [REQUIRED] The output location where .json doc file will be written to.
    c.file_output_path = 'public/open_api'
  
    c.open_api_docs = {
        # The definition of the document `homepage`.
        homepage: {
            # [REQUIRED] ZRO will scan all the descendants of root_controller, then generate their docs.
            root_controller: Api::V1::BaseController,
  
            # [REQUIRED] OAS Info Object: The section contains API information.
            info: {
                # [REQUIRED] The title of the application.
                title: 'Homepage APIs',
                # Description of the application.
                description: 'API documentation of Rails Application. <br/>' \
                             'Optional multiline or single-line Markdown-formatted description ' \
                             'in [CommonMark](http://spec.commonmark.org/) or `HTML`.',
                # [REQUIRED] The version of the OpenAPI document
                # (which is distinct from the OAS version or the API implementation version).
                version: '1.0.0'
            }
        }
    }
  end
  ```
  
  In addition to directly using Hash,
  you can also use DSL to define the document information:
  
  ```ruby
  # config/initializers/open_api.rb
  require 'open_api'
  
  OpenApi::Config.tap do |c|
    c.instance_eval do
      open_api :homepage_api, root_controller: ApiDoc
      info version: '1.0.0', title: 'Homepage APIs'
    end
  end
  ```
  
  For more detailed configuration: [open_api.rb](documentation/examples/open_api.rb)  
  See all the settings you can configure: [config.rb](lib/open_api/config.rb)  
  See all the Document Definition DSL: [config_dsl.rb](lib/open_api/config_dsl.rb)

## Usage - DSL

### First of all, `include OpenApi::DSL` to your base class (which is for writing docs), for example:

  ```ruby
  # app/controllers/api/api_controller.rb
  class ApiController < ActionController::API
    include OpenApi::DSL
  end
  ```

### DSL Usage Example

  Here is the simplest usage:
  
  ```ruby
  class Api::V1::ExamplesController < Api::V1::BaseController
    api :index, 'GET list' do
      query :page, Integer#, desc: 'page, greater than 1', range: { ge: 1 }, dft: 1
      query :rows, Integer#, desc: 'per page', range: { ge: 1 }, default: 10
    end
  end
  ```
  
  For more example, see [goods_doc.rb](documentation/examples/goods_doc.rb), and
  [examples_controller.rb](documentation/examples/examples_controller.rb)

### DSL as class methods ([source code](lib/open_api/dsl.rb))

#### (1) `ctrl_path` (controller path) [optional if you're writing DSL in controller]

  ```ruby
  # method signature
  ctrl_path(path)
  # usage
  ctrl_path 'api/v1/examples'
  ```
  It is optional because `ctrl_path` defaults to `controller_path`.
  
  [Here's a trick](#trick1---write-the-dsl-somewhere-else): Using `ctrl_path`, you can write the DSL somewhere else 
  to simplify the current controller.  

#### (2) `apis_tag` [optional]

  ```ruby
  # method signature
  apis_tag(name: nil, desc: '', external_doc_url: '')
  # usage
  apis_tag name: 'ExampleTagName', desc: 'ExamplesController\'s APIs'
  ```
  This method allows you to set the Tag (which is a node of [OpenApi Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#openapi-object)).  
  
  desc and external_doc_url will be output to the tags[the current tag] (tag defaults to controller_name), but are optional. 

#### (3) `components` [optional]

  ```ruby
  # method signature
  components(&block)
  # usage
  components do
    # DSL for defining components
    schema :DogSchema => [ { id: Integer, name: String }, dft: { id: 1, name: 'pet' } ]
    query! :UidQuery  => [ :uid, String, desc: 'uid' ]
    resp   :BadRqResp => [ 'bad request', :json ]
  end
  
  # to use component
  api :action, 'summary' do
    query :doge, :DogSchema # to use a Schema component
    param_ref :UidQuery     # to use a Parameter component
    response_ref :BadRqResp # to use a Response component
  end
  ```
  Component can be used to simplify your DSL code (by using `*_ref` methods).
  
  Each RefObj you defined is associated with components through component key.
  We suggest that component keys should be camelized symbol.

#### (4) `api_dry` [optional]

  This method is for DRYing.
  
  ```ruby
  # method signature
  api_dry(action = :all, desc = '', &block)
  # usage
  api_dry :all, 'common response' # block ...
  api_dry :index # block ...
  api_dry [:index, :show] do
    query! #...
  end
  ```
  
  As you think, the block will be executed to each specified API(action) **firstly**.
  
#### (5) `api` [required]

  Define the specified API (controller action, in the following example is index).
  
  ```ruby
  # method signature
  api(action, summary = '', skip: [ ], use: [ ], &block)
  # usage
  api :index, '(SUMMARY) this api blah blah ...', # block ...
  ```
  
  `use` and `skip` options: to use or skip the parameters defined in `api_dry`.
  
  [Note] JBuilder file automatic generator has been removed,
  If you need this function, please refer to [here](https://github.com/zhandao/zero-rails/tree/master/lib/generators/jubilder/dsl.rb) 
  to implement a lib.
  
  ```ruby
  api :show, 'summary', use: [:id] # => it will only take :id from DRYed result.
  ```

### DSL methods inside [api]() and [api_dry]()'s block

  [source code](lib/open_api/dsl/api_info_obj.rb)
  
  These following methods in the block describe the specified API action: description, valid?,
  parameters, request body, responses, securities, servers.
  
  (Here corresponds to OAS [Operation Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#operationObject))

#### (1) `this_api_is_invalid!`, its aliases:
  ```
  this_api_is_expired!
  this_api_is_unused!
  this_api_is_under_repair!
  ```

  ```ruby
  # method signature
  this_api_is_invalid!(explain = '')
  # usage
  this_api_is_invalid! 'this api is expired!'
  ```
  
  Then `deprecated` of this API will be set to true.

#### (2) `desc`: description for the current API and its inputs (parameters and request body)

  ```ruby
  # method signature
  desc(desc, param_descs = { })
  # usage
  desc 'current API\'s description',
       id:    'desc of the parameter :id',
       email: 'desc of the parameter :email'
  ```

  You can of course describe the input in it's DSL method (like `query! :done ...`, [this line](https://github.com/zhandao/zero-rails_openapi#-dsl-usage-example)), 
  but that will make it long and ugly. We recommend that unite descriptions in this place.
  
  In addition, when you want to dry the same parameters (each with a different description), it will be of great use.

#### (3) `param` family methods (OAS - [Parameter Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#parameterObject))

  Define the parameters for the API (action).
  ```
  param
  param_ref                          # for reuse component, 
                                     #   it links sepcified RefObjs (by component keys) to current parameters.
  header,  path,  query,  cookie     # will pass specified parameter location to `param`
  header!, path!, query!, cookie!    # bang method of above methods
  do_* by: { parameter_definations } # batch definition parameters, such as do_path, do_query
  order                              # order parameters by names array you passed
  examples                           # define examples of parameters
  ```
  **The bang method (which's name is end of a exclamation point `!`) means this param is required, so without `!` means optional.**  
  **THE SAME BELOW.**

  ```ruby
  # `param_type` just is the location of parameter, like: query, path
  # `schema_type` is the type of parameter, like: String, Integer (must be a constant)
  # For more explanation, please click the link below ↓↓↓
  # method signature
  param(param_type, param_name, schema_type, is_required, schema_hash = { })
  # usage
  param :query, :page, Integer, :req,  range: { gt: 0, le: 5 }, desc: 'page'
  
  
  # method signature
  param_ref(component_key, *component_keys) # should pass at least 1 key
  # usage
  param_ref :IdPath
  param_ref :IdPath, :NameQuery, :TokenHeader
  
  
  ### method signature
   header(param_name, schema_type = nil, one_of: nil, all_of: nil, any_of: nil, not: nil, **schema_hash)
  header!(param_name, schema_type = nil, one_of: nil, all_of: nil, any_of: nil, not: nil, **schema_hash)
   query!(param_name, schema_type = nil, one_of: nil, all_of: nil, any_of: nil, not: nil, **schema_hash)
  # ...
  ### usage
  header! 'Token', String
  query!  :readed, Boolean, must_be: true, default: false
  # The same effect as above, but not simple
  param :query, :readed, Boolean, :req, must_be: true, default: false
  #
  # When schema_type is a Object 
  #   (describe by hash, key means prop's name, value means prop's schema_type)
  query :good, { name: String, price: Float, spec: { size: String, weight: Integer } }, desc: 'good info'
  # Or you can use `type:` to sign the schema_type, maybe this is clearer for describing object
  query :good, type: { name: String, price: Float, spec: { size: String, weight: Integer } }, desc: 'good info'
  #
  query :good_name, type: String # It's also OK, but some superfluous
  query :good_name, String       # recommended
  # About Combined Schema (`one_of` ..), see the link below.


  # method signature
  do_query(by:)
  # usage
  do_query by: {
    search_type: String,
     search_val: String,
        export!: Boolean
  }
  # The same effect as above, but a little bit repetitive
  query  :search_type, String
  query  :search_val, String
  query! :export, Boolean
  
  
  # method signature
  # `exp_by` (select_example_by): choose the example fields.
  examples(exp_by = :all, examples_hash)
  # usage
  # it defines 2 examples by using parameter :id and :name
  # if pass :all to `exp_by`, keys will be all the parameter's names.
  examples [:id, :name], {
          :right_input => [ 1, 'user'], # == { id: 1, name: 'user' }
          :wrong_input => [ -1, ''   ]
  }
  ```
  
  [This trick show you how to define combined schema (by using `one_of` ..)](#trick6---combined-schema-one-of--all-of--any-of--not)

  [**>> More About `param` DSL <<**](documentation/parameter.md)

#### (4) `request_body` family methods (OAS - [Request Body Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#requestBodyObject))

  OpenAPI 3.0 uses the requestBody keyword to distinguish the payload from parameters.
  ```
  request_body
  body_ref      # for reuse component, 
                #   it links sepcified RefObjs (by component keys) to current body.
  body, body!   # alias of request_body
  form, form!   # define a multipart/form-data body
  file, file!   # define a File media-type body
  ```
  
  ```ruby
  # method signature
  request_body(is_required, media_type, desc = '', schema_hash = { })
  # usage
  request_body :opt, :form, '', type: { id!: Integer, name: String }
  # or
  request_body :opt, :form, '', data: { id!: Integer, name: String }


  # method signature
  body_ref(component_key)
  # usage
  body_ref :UpdateDogeBody


  # method signature
  body!(media_type, desc = '', schema_hash = { })
  # usage
  body :json
  
  
  # method implement
  def form desc = '', schema_hash = { }
    body :form, desc, schema_hash
  end
  # usage
  form! 'register', data: {
          name: String,
          password: String,
          password_confirmation: String
      }
  # advance usage
  form 'for creating a user', data: {
              :name! => { type: String, desc: 'user name' },
          :password! => { type: String, pattern: /[0-9]{6,10}/, desc: 'password' },
          # optional
            :remarks => { type: String, desc: 'remarks' },
      }, exp_by:            %i[ name password ],
         examples: {         #    ↓        ↓
             :right_input => [ 'user1', '123456' ],
             :wrong_input => [ 'user2', 'abc'    ]
         }


  # about `file`
  def file! media_type, desc = '', schema_hash = { type: File }
    body! media_type, desc, schema_hash
  end
  ```
  
  1. **Notice:** Each API should only declare a request body
     That is, all of the above methods you can only choose one of them.  
     (But **multiple media types** will be supported in the future).
  2. `media_type`: we provide some [mapping](lib/oas_objs/media_type_obj.rb) from symbols to real media-types.  
  3. `schema_hash`: as above (see param).  
     **One thing that should be noted is: when use Hash writing, `scham_type` is writed in schema_hash using key :type.**
  4. `exp_by` and `examples`: for the above example, the following has the same effect:
     ```
     examples: {
         :right_input => { name: 'user1', password: '123456' },
         :wrong_input => { name: 'user2', password: 'abc' }
     }
     ```
  
#### (5) `response` family methods (OAS - [Response Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#response-object))
  
  Define the responses for the API (action).
  ```
  response or resp
  response_ref
  default_response or dft_resp
  error_response, other_response, oth_resp, error, err_resp # response's aliases, should be used in the error response context.
  merge_to_resp
  ```
  
  ```ruby
  # method signature
  response(response_code, desc, media_type = nil, schema_hash = { })
  # usage
  response 200, 'query result', :pdf, type: File

  # method signature
  response_ref(code_compkey_hash)
  # usage
  response_ref 700 => :AResp, 800 => :BResp

  # method signature
  merge_to_resp(code, by:)
  # usage
  merge_to_resp 200, by: {
      data: {
          type: String
      }
  }
  ```
  
  **practice:** Combined with wrong class, automatically generate error responses. [AutoGenDoc](documentation/examples/auto_gen_doc.rb#L63)  
  
#### (6) Authentication and Authorization
  
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
  # method signature
  security_scheme(scheme_name, other_info)
  # usage
  security_scheme :BasicAuth, { type: 'http', scheme: 'basic', desc: 'basic auth' }
  
  # method signature
  base_auth(scheme_name, other_info = { })
  bearer_auth(scheme_name, format = 'JWT', other_info = { })
  api_key(scheme_name, field:, in:, **other_info)
  # usage
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
  # method signature
  security_require(scheme_name, scopes: [ ])
  # usage
  global_auth :Token
  need_auth   :Token
  auth :OAuth, scopes: %w[ read_example admin ]
  ```

#### (7) Overriding Global Servers by `server`
  
  ```ruby
  # method signature
  server(url, desc)
  # usage
  server 'http://localhost:3000', 'local'
  ```
  
### DSL methods inside [components]()'s block ([code source](lib/open_api/dsl/components.rb))

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
  # method signature
  schema(component_key, type = nil, one_of: nil, all_of: nil, any_of: nil, not: nil, **schema_hash)
  # usage
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
  [1] see: [Type](documentation/parameter.md#type-schema_type)
  
## Usage - Generate JSON Documentation File

  Use `OpenApi.write_docs`:
  
  ```ruby
  # initializer
  OpenApi.write_docs generate_files: !Rails.env.production?
  
  # or run directly in console
  OpenApi.write_docs # will generate json doc files
  ```
  
  Then the JSON files will be written to the directories you set. (Each API a file.)

## Usage - Use Swagger UI(very beautiful web page) to show your Documentation

  Download [Swagger UI](https://github.com/swagger-api/swagger-ui) (version >= 2.3.0 support the OAS3) 
  to your project,  
  change the default JSON file path(url) in index.html.  
  In order to use it, you may have to enable CORS, [see](https://github.com/swagger-api/swagger-ui#cors-support)

## Tricks

### Trick1 - Write the DSL Somewhere Else

  Does your documentation take too many lines?  
  Do you want to separate documentation from business controller to simplify both?  
  Very easy! Just follow
  
  ```ruby
  # config/initializers/open_api.rb
  # in your configuration
  root_controller: ApiDoc
  
  # app/api_doc/api_doc.rb
  require 'open_api/dsl'
  
  class ApiDoc < Object
    include OpenApi::DSL
  end
  
  # app/api_doc/v1/examples_doc.rb
  class V1::ExamplesDoc < ApiDoc
    ctrl_path 'api/v1/examples'
    
    api :index do
      # ...
    end
  end
  ```
  
  Notes: file name ends in `_doc.rb` by default, but you can change via `Config.doc_location`
  (it should be file paths, defaults to `./app/**/*_doc.rb`).

### Trick2 - Global DRYing

  Method `api_dry` is for DRY but its scope is limited to the current controller.
  
  I have no idea of best practices, But you can look at this [file](documentation/examples/auto_gen_doc.rb).  
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
  query :view, String, desc: 'allows values<br/>', enum: {
          'all goods (default)': :all,
                  'only online': :online,
                 'only offline': :offline,
              'expensive goods': :get,
                  'cheap goods': :borrow,
  }
  ```
  Read this [file](documentation/examples/auto_gen_desc.rb) to learn more.

### Trick4 - Skip or Use parameters define in api_dry

  Pass `skip: []` and `use: []` to `api` like following code:
  ```ruby
  api :index, 'desc', skip: [ :Token ]
  ```
  
  Look at this [file](documentation/examples/goods_doc.rb) to learn more.

### Trick5 - Auto Generate index/show Actions's Response-Types Based on DB Schema

  Use method `load_schema` in `api_dry`.
  
  See this [file](documentation/examples/auto_gen_doc.rb#L51) for uasge information.

### Trick6 - Combined Schema (one_of / all_of / any_of / not)

  ```ruby
  query :combination, one_of: [ :GoodSchema, String, { type: Integer, desc: 'integer input'}]
  
  form '', data: {
      :combination_in_form => { any_of: [ Integer, String ] }
  }
  
  schema :PetSchema => [ not: [ Integer, Boolean ] ]
  ```
  
  OAS: [link1](https://swagger.io/docs/specification/data-models/oneof-anyof-allof-not/),
  [link2](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#schemaObject)

## Troubleshooting

- **You wrote document of the current API, but not find in the generated json file?**  
  Check your routing settings.
- **Undefine method `match?`**  
  Monkey patches for `String` and `Symbol`:  
  ```ruby
  class String # Symbol
    def match?(pattern); !match(pattern).nil? end
  end
  ```
- **Report error when require `routes.rb`?***
  1. Run `rails routes`.
  2. Copy the output to a file, for example `config/routes.txt`.  
     Ignore the file `config/routes.txt`.
  3. Put `c.rails_routes_file = 'config/routes.txt'` to your ZRO config.


## About `OpenApi.docs` and `OpenApi.paths_index`

  After `OpenApi.write_docs`, the above two module variables will be generated.
  
  `OpenApi.docs`: A Hash with API names as keys, and documents of each APIs as values.  
  documents are instances of ActiveSupport::HashWithIndifferentAccess.
  
  `OpenApi.paths_index`: Inverted index of controller path to API name mappings.  
  Like: `{ 'api/v1/examples' => :homepage_api }`  
  It's useful when you want to look up a document based on a controller and do something.

## Development

  After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
  
  To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

  The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

  Everyone interacting in the Zero-OpenApi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
