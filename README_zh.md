# ZRO: Rails 应用 OpenApi3 JSON 文档生成器

  [![Gem Version](https://badge.fury.io/rb/zero-rails_openapi.svg)](https://badge.fury.io/rb/zero-rails_openapi)
  [![Build Status](https://travis-ci.org/zhandao/zero-rails_openapi.svg?branch=master)](https://travis-ci.org/zhandao/zero-rails_openapi)
  [![Maintainability](https://api.codeclimate.com/v1/badges/471fd60f6eb7b019ceed/maintainability)](https://codeclimate.com/github/zhandao/zero-rails_openapi/maintainability)
  [![Test Coverage](https://api.codeclimate.com/v1/badges/471fd60f6eb7b019ceed/test_coverage)](https://codeclimate.com/github/zhandao/zero-rails_openapi/test_coverage)
  [![Gitter Chat](https://badges.gitter.im/zero-rails_openapi/Lobby.svg)](https://gitter.im/zero-rails_openapi/Lobby)
  
  一套简洁的 DSL，用于为 Rails 应用生成 OpenAPI Specification 3 (**OAS3**, 旧称「Swagger3」) 标准的 JSON 文档。  
  （你还可以使用 Swagger-UI 3.2.0 以上版本来可视化所生成的文档。）

## Contributing

  **这里是栈刀 = ▽ =  
  如果你在寻找能清晰书写 OAS API 文档的 DSL 工具，俺这个还挺不错的 ~  
  你还可以复用其所[产出](#about-openapidocs-and-openapiroutes_index)来写一些扩展，比如参数自动校验什么的（我有写哦）。  
  有什么想法敬请 PR，谢过！
  另外，走过路过不妨来个 star？**
  
  另外，如果对其行为表现有任何疑惑，请先阅读测试代码，这其中已表明我的大多数考量。  
  可一读：[api DSL](spec/api_spec.rb) 以及 [schema Obj](spec/oas_objs/schema_obj_spec.rb)。


## Table of Contents

- [关于 OAS](#about-oas) (OpenAPI Specification)
- [安装](#installation)
- [配置](#configure)
- [DSL 介绍及用例](#usage---dsl)
  - [基本的 DSL](#基本的-dsl)
    - [route_base](#1-route_base-optional-if-youre-writing-dsl-in-controller)
    - [doc_tag](#2-doc_tag-optional)
    - [components](#3-components-optional)
    - [api_dry](#4-api_dry-optional)
    - [api](#5-api-required)
  - [用于 `api` 和 `api_dry` 块内的 DSL（描述 API 的参数、响应等）](#dsl-methods-inside-api-and-api_drys-block)
    - [this_api_is_invalid!](#1-this_api_is_invalid-its-aliases)
    - [desc](#2-desc-description-for-the-current-api-and-its-inputs-parameters-and-request-body)
    - [param family methods](#3-param-family-methods-oas---parameter-object)
    - [request_body family methods](#4-request_body-family-methods-oas---request-body-object)
    - [response family methods](#5-response-family-methods-oas---response-object)
    - [callback](#6-callback-oas---callback-object)
    - [Authentication and Authorization](#7-authentication-and-authorization)
    - [server](#8-overriding-global-servers-by-server)
  - [用于 `components` 块内的 DSL（描述可复用的组件）](#dsl-methods-inside-componentss-block-code-source)
- [执行文档生成](#run---generate-json-documentation-file)
- [使用 Swagger-UI 可视化所生成的文档](#use-swagger-uivery-beautiful-web-page-to-show-your-documentation)
- [技巧](#tricks)
  - [将 DSL 写于他处，与控制器分离](#trick1---write-the-dsl-somewhere-else)
  - [全局 DRY](#trick2---global-drying)
  - [基于 enum 等信息自动生成参数描述](#trick3---auto-generate-description)
  - [跳过或使用 DRY 时（`api_dry`）所定义的参数](#trick4---skip-or-use-parameters-define-in-api_dry)
  - [基于 DB Schema 自动生成 response 的格式](#trick5---auto-generate-indexshow-actionss-response-types-based-on-db-schema)
  - [定义组合的 Schema (one_of / all_of / any_of / not)](#trick6---combined-schema-one_of--all_of--any_of--not)
- [问题集](#troubleshooting)
- [有关 `OpenApi.docs` 和 `OpenApi.routes_index`](#about-openapidocs-and-openapiroutes_index)

## About OAS

  有关 OAS3 的所有内容请看 [OpenAPI Specification](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md)
  
  你也可以看这份文档做初步的了解 [swagger.io](https://swagger.io/docs/specification/basic-structure/)
  
  **建议你应该至少了解 OAS3 的基本结构**，比如说 component（组件）—— 这能帮助你进一步减少书写文档 DSL 的代码（如果其中有很多可复用的数据结构的话）。

## Installation

  选一行添加到 Gemfile:
  
  ```ruby
  gem 'zero-rails_openapi'
  # or
  gem 'zero-rails_openapi', github: 'zhandao/zero-rails_openapi'
  ```
  
  命令行执行：
  
      $ bundle
  
## Configure

  新建一个 initializer, 用来配置 ZRO 并定义你的文档。
  
  这是一个简单的示例：
  
  ```ruby
  # config/initializers/open_api.rb
  require 'open_api'
  
  OpenApi::Config.tap do |c|
    # [REQUIRED] The output location where .json doc file will be written to.
    c.file_output_path = 'public/open_api'
  
    c.open_api_docs = {
        # 对文档 `homepage` 进行定义
        homepage: {
            # [REQUIRED] ZRO will scan all the descendants of base_doc_classes, then generate their docs.
            base_doc_classes: [Api::V1::BaseController],
  
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
  
  除了直接使用 Hash，你还可以使用 DSL 来定义文档的基本信息：
  
  ```ruby
  # config/initializers/open_api.rb
  require 'open_api'
  
  OpenApi::Config.tap do |c|
    c.file_output_path = 'public/open_api'

    c.instance_eval do
      open_api :homepage_api, base_doc_classes: [ApiDoc]
      info version: '1.0.0', title: 'Homepage APIs'
    end
  end
  ```
  
  更多更详尽的配置和文档信息定义示例: [open_api.rb](documentation/examples/open_api.rb) 
  所有你可以配置的项目: [config.rb](lib/open_api/config.rb)
  所有你可以使用的文档信息 DSL: [config_dsl.rb](lib/open_api/config_dsl.rb)

## Usage - DSL

### 首先，`include OpenApi::DSL` 到你用来写文档的基类中，例如：

  ```ruby
  # app/controllers/api/api_controller.rb
  class ApiController < ActionController::API
    include OpenApi::DSL
  end
  ```

### DSL 使用实例

  一个最简单的实例：
  
  ```ruby
  class Api::ExamplesController < ApiController
    api :index, 'GET list' do
      query :page, Integer#, desc: 'page, greater than 1', range: { ge: 1 }, dft: 1
      query :rows, Integer#, desc: 'per page', range: { ge: 1 }, default: 10
    end
  end
  ```
  
  更多更详细的实例： [goods_doc.rb](documentation/examples/goods_doc.rb)、
  [examples_controller.rb](documentation/examples/examples_controller.rb)，以及
  [这里](https://github.com/zhandao/zero-rails/tree/master/app/_docs/v1)。

### 基本的 DSL ([source code](lib/open_api/dsl.rb))

#### (1) `route_base` [无需调用，当且仅当你是在控制器中写文档时]

  ```ruby
  # method signature
  route_base(path)
  # usage
  route_base 'api/v1/examples'
  ```
  其默认设定为 `controller_path`。
  
  [这个技巧](#trick1---write-the-dsl-somewhere-else) 展示如何使用 `route_base` 来让你将 DSL 写在他处（与控制器分离），来简化你的控制器。

#### (2) `doc_tag` [optional]

  ```ruby
  # method signature
  doc_tag(name: nil, desc: '', external_doc_url: nil)
  # usage
  doc_tag name: 'ExampleTagName', desc: "ExamplesController's APIs"
  ```
  该方法可以设置当前类中声明的 API 的 Tag
  (Tag 是一个 [OpenApi Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#openapi-object)节点)。

  Tag 的名字默认为 controller_name，除了名字，还可以设置可选参数 desc 和 external_doc_url。

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
  Component 用以简化你的 DSL 代码 (即通过 `*_ref` 形式的方法，来引用已定义的 Component 对象)。

  每个 RefObj 都是通过 component key 来关联指定的 component。
  我们建议 component key 规范为驼峰命名法，且必须是 Symbol。

#### (4) `api_dry` [optional]

  顾名思义，此方法用于 DRY。

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

  如你所觉，传给该方法的块，将会 eval 到指定的 API 的**开头**。

#### (5) `api` [required]

  定义指定 API (或者说是一个 controller action).

  ```ruby
  # method signature
  api(action, summary = '', http: nil, skip: [ ], use: [ ], &block)
  # usage
  api :index, '(SUMMARY) this api blah blah ...', # block ...
  ```

  `use` 和 `skip`: 指定使用或者跳过在 `api_dry` 中声明的参数。

  ```ruby
  api :show, 'summary', use: [:id] # 将会从 dry 块中声明的参数中挑出 id 这个参数用于 API :show
  ```

### 用于 [`api`]() 和 [`api_dry`]() 块内的 DSL

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

  You can of course describe the input in it's DSL method (like `query! :done ...`, [this line](https://github.com/zhandao/zero-rails_openapi#dsl-usage-example)),
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
  param(param_type, param_name, schema_type, is_required, schema_info = { })
  # usage
  param :query, :page, Integer, :req,  range: { gt: 0, le: 5 }, desc: 'page'


  # method signature
  param_ref(component_key, *component_keys) # should pass at least 1 key
  # usage
  param_ref :IdPath
  param_ref :IdPath, :NameQuery, :TokenHeader


  ### method signature
   header(param_name, schema_type = nil, **schema_info)
  header!(param_name, schema_type = nil, **schema_info)
   query!(param_name, schema_type = nil, **schema_info)
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
  # `exp_params` (select_example_by): choose the example fields.
  examples(exp_params = :all, examples_hash)
  # usage
  # it defines 2 examples by using parameter :id and :name
  # if pass :all to `exp_params`, keys will be all the parameter's names.
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
  data          # define [a] property in the form-data body
  file, file!   # define a File media-type body
  ```
  Bang methods(!) means the specified media-type body is required.

  ```ruby
  # method signature
  request_body(required, media_type, data: { }, **options)
  # usage
  # (1) `data` contains all the attributes required by this request body.
  # (2) `param_name!` means it is required, otherwise without '!' means optional.
  request_body :opt, :form, data: { id!: Integer, name: { type: String, desc: 'name' } }, desc: 'form-data'


  # method signature
  body_ref(component_key)
  # usage
  body_ref :UpdateDogeBody


  # method signature
  body!(media_type, data: { }, **options)
  # usage
  body :json


  # method implement
  def form data:, **options
    body :form, data: data, **options
  end
  # usage
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
  }, exp_params:            %i[ name password ],
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
  # usage: please look at the 4th point below

  # about `file`
  def file! media_type, data: { type: File }, **options
    body! media_type, data: data, **options
  end
  ```

  1. `media_type`: we provide some [mapping](lib/oas_objs/media_type_obj.rb) from symbols to real media-types.
  2. `schema_info`: as above (see param).
  3. `exp_params` and `examples`: for the above example, the following has the same effect:
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
  # method signature
  response(code, desc, media_type = nil, data: { }, type: nil)
  # usage
  resp 200, 'json response', :json, data: { name: 'test' }
  response 200, 'query result', :pdf, type: File
  # same as:
  response 200, 'query result', :pdf, data: File

  # method signature
  response_ref(code_compkey_hash)
  # usage
  response_ref 700 => :AResp, 800 => :BResp
  ```

  **practice:** Automatically generate responses based on the agreed error class. [AutoGenDoc](documentation/examples/auto_gen_doc.rb#L63)

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
  server(url, desc: '')
  # usage
  server 'http://localhost:3000', desc: 'local'
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
  schema(component_key, type = nil, **schema_info)
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
  Do you want to separate documentation from business controller to simplify both?  
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
  query :view, String, desc: 'allows values<br/>', enum!: {
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

  Everyone interacting in the Zero-OpenApi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
