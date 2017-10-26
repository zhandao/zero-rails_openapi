# ZRO: OpenApi 3 DocGenerator for Rails

[![Gem Version](https://badge.fury.io/rb/zero-rails_openapi.svg)](https://badge.fury.io/rb/zero-rails_openapi)
[![Build Status](https://travis-ci.org/zhandao/zero-rails_openapi.svg?branch=master)](https://travis-ci.org/zhandao/zero-rails_openapi)

Provide concise DSL for generating the OpenAPI Specification 3 (**OAS3**, formerly Swagger3) documentation JSON file for Rails application, 
then you can use Swagger UI 3.2.0+ to show the documentation.

## Contributing

**Hi, here is ZhanDao. This gem was completed when I learned Ruby less than three months, 
I'm not sure if it has problem, but it may have a lot to improve.  
I'm looking forward to your issues and PRs, thanks!**

Currently, I think the most important TODO is the Unit Test (RSpec, I want is), 
but I dont have enough time now = ▽ =

## Table of Contents

- [About OAS](#about-oas) (OpenAPI Specification)
- [Installation](#installation)
- [Configure](#configure)
- [Usage](#usage)
  - [DSL for documenting your controller](#dsl-for-documenting-your-controller)
  - [Generate JSON documentation file](#generate-json-documentation-file)
  - [Use Swagger UI(very beautiful web page) to show your Documentation](#use-swagger-uivery-beautiful-web-page-to-show-your-documentation)
  - [Tricks](#tricks)
    - [Write DSL somewhere else](#trick1---write-the-dsl-somewhere-else)
    - [Global DRYing](#trick2---global-drying)
    - [Auto generate description](#trick3---auto-generate-description)
    - [Skip or Use parameters define in api_dry](#trick4---skip-or-use-parameters-define-in-api_dry)
    - [Atuo Generate index/show Actions's Responses Based on DB Schema](#trick5)
- [Troubleshooting](#troubleshooting)

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
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zero-rails_openapi
    
## Configure

Create an initializer, configure ZRO and define your APIs.

This is the simplest configuration example:

```ruby
# config/initializers/open_api.rb
require 'open_api'

OpenApi::Config.tap do |c|
  # [REQUIRED] The output location where .json doc file will be written to.
  c.file_output_path = 'public/open_api'

  c.register_docs = {
      homepage_api: {
          # [REQUIRED] ZRO will scan all the descendants of root_controller, then generate their docs.
          root_controller: Api::V1::BaseController,

          # [REQUIRED] OAS Info Object: The section contains API information.
          info: {
              # [REQUIRED] The title of the application.
              title: 'Rails APIs',
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
You can also set the *global configuration(/component)* of OAS: 
Server Object / Security Scheme Object / Security Requirement Object ...

For more detailed configuration: [open_api.rb](https://github.com/zhandao/zero-rails_openapi/blob//examples/open_api.rb)

## Usage

### DSL for documenting your controller

#### \> First of all, extend DSL for your base controller, for example:

```ruby
# application_controller.rb
require 'open_api/dsl'

class ApplicationController < ActionController::API
  include OpenApi::DSL
 end
```

#### \> [DSL Usage Example](https://github.com/zhandao/zero-rails_openapi/blob/masterdocumentation/examples/examples_controller.rb)

(TODO: I consider that, here should be put in a the simplest case.)
```ruby
class Api::V1::ExamplesController < Api::V1::BaseController
  apis_set 'ExamplesController\'s APIs' do
    schema :Dog           => [ String, must_be: 'doge' ]
    query! :QueryCompUuid => [ :product_uuid, String, desc: 'product uuid' ]
    path!  :PathCompId    => [ :id, Integer, desc: 'user id' ]
    resp   :RespComp      => [ 'bad request', :json ]
    body!  :RqBodyComp    => [ :form ]
  end

  api_dry %i[index show], 'common response' do
    response '567', 'query result export', :pdf, type: File
  end

  open_api :index, '(SUMMARY) this api blah blah ...', :builder_template1 do
    this_api_is_invalid! 'this api is expired!'
    desc 'Optional multiline or single-line Markdown-formatted description',
         id:         'user id',
         email_addr: 'email_addr\'s desc'
    email = 'git@github.com'

    query! :id,         Integer, enum: 0..5,     length: [1, 2], pattern: /^[0-9]$/, range: {gt:0, le:5}
    query! :done,       Boolean, must_be: false, default: true,  desc: 'must be false'
    query  :email_addr, String,  lth: :ge_3,     default: email  # is_a: :email
    # form! 'form', type: { id!: Integer, name: String }
    file :pdf, 'desc: the media type is application/pdf'
    
    response :success, 'success response', :json, type: :Dog
    
    security :ApiKeyAuth
  end

  open_api :show do
    param_ref    :PathCompId, :QueryCompUuid
    response_ref '123' => :RespComp, '223' => :RespComp
  end
end

```

#### \> Explanation

#### \>\> controller class methods ([source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl.rb))

- `ctrl_path` (controller path) [Optional]

  ```ruby
  # method signature
  ctrl_path path
  # usage
  ctrl_path 'api/v1/examples'
  ```
  This option allows you to set the Tag* (which is a node of [OpenApi Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#openapi-object)).  
  [Here's a trick](#write-the-dsl-somewhere-else-recommend): Using `ctrl_path`, you can write the DSL somewhere else 
  to simplify the current controller.  
  \* take the tag from `path.split('/').last`

- `apis_set` [Optional]

  ```ruby
  # method signature
  apis_set desc = '', external_doc_url = '', &block
  # usage
  apis_set 'ExamplesController\'s APIs' do
    # DSL for defining components
  end
  ```
  desc and external_doc_url will be output to the tags[the current tag] (tag defaults to controller_name ), but are optional. 
  the focus is on the block, the DSL methods in the block will generate components.

- `api_dry` [Optional]

  this method is for DRYing.
  
  ```ruby
  # method signature
  api_dry method = :all, desc = '', &block
  # usage
  api_dry :all, 'common response' do; end
  api_dry :index do; end
  api_dry [:index, :show] do; end
  ```
  
  As you think, the DSL methods in the block will be executed to each API that you set by method.
  
- `open_api` [Required]

  Define the specified API (in the following example is index).
  
  ```ruby
  # method signature
  open_api method, summary = '', options = { }, &block
  # usage
  open_api :index, '(SUMMARY) this api blah blah ...', builder: template1 do end
  ```
  If pass `builder` or `bd` to the third parameter,
  and `generate_jbuilder_file` in your setting file is set `true`,
  ZRO will generate JBuilder file by using specified template that you set
  `template1` in your setting file.  
  For example, see: [open_api.rb](https://github.com/zhandao/zero-rails_openapi/blob//examples/open_api.rb)


#### \>\> DSL methods inside *open_api* and *api_dry*'s block ([source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl_inside_block.rb):: ApiInfoObj)

These methods in the block describe the specified API(s): description, valid?,
parameters, request body, responses, securities, servers.

(Here corresponds to OAS [Operation Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#operationObject))

- `this_api_is_invalid!`, its aliases are:
  - `this_api_is_expired!`
  - `this_api_is_unused!`
  - `this_api_is_under_repair!`

  ```ruby
  # method signature
  this_api_is_invalid! explain = ''
  # usage
  this_api_is_invalid! 'this api is expired!'
  ```

- `desc`: description for current API and its inputs (parameters and request body)

  ```ruby
  # method signature
  desc desc, inputs_descs = { }
  # usage
  desc 'current API\'s description',
       id:         'user id',
       email_addr: 'email_addr\'s desc'
  ```

  You can of course describe the input in it's DSL method (like `query! :done` [this line](https://github.com/zhandao/zero-rails_openapi#-dsl-usage-example)), 
  but that will make it long and ugly. We recommend that unite descriptions in this place.
  
  In addition, when you want to dry the same parameters (each with a different description), it will be of great use.

- param family methods (OAS - [Parameter Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#parameterObject))
  - `param`
  - `param_ref`
  - `header`, `path`, `query`, `cookie` and bang methods: `header!`, `path!`, `query!`, `cookie!`  
  **The bang method(`!`) means it is required, so it is optional without `!`, the same below.**

  Define the parameters for the API(operation).
  You can use the Reference Object to link to parameters that are defined at the components/parameters by method param_ref().

  ```ruby
  # method signature
  param param_type, name, type, required, schema_hash = { }
  # usage
  param :query,    :page, Integer, :req,  range: { gt: 0, le: 5 }, desc: 'page'
  
  # method signature
  param_ref component_key, *component_keys
  # usage
  param_ref :PathCompId
  param_ref :PathCompId, :QueryCompUuid, ...
  
  # method signature
  header  name, type, schema_hash = { }
  header! name, type, schema_hash = { }
  query!  name, type, schema_hash = { }
  # usage
  header! :'Token', String
  query!  :done,      Boolean, must_be: false, default: true
  ```

  [**>> More About Param DSL <<**](https://github.com/zhandao/zero-rails_openapi/blob//parameter.md)

- request_body family methods (OAS - [Request Body Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#requestBodyObject))
  - `request_body`
  - `body_ref`
  - `body` and bang `body!`
  - `form`, `form!`; `file`, `file!`
  
  OpenAPI 3.0 uses the requestBody keyword to distinguish the payload from parameters.  
  Define the request body for the API(operation).
  You can use the Reference Object to link to request body that is defined at the components/requestBodies by method body_ref().
  
  ```ruby
  # method signature
  request_body required, media_type, desc = '', schema_hash = { }
  # usage
  request_body :opt, :form, type: { id!: Integer, name: String }

  # method signature
  body_ref component_key
  # usage
  body_ref :Body

  # method signature
  body(!) media_type, desc = '', schema_hash = { }
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
          :name! =>     { type: String, desc: 'user name' },
          :password! => { type: String, pattern: /[0-9]{6,10}/, desc: 'password' },
          # optional
          :remarks =>   { type: String, desc: 'remarks' },
      }

  # method implement
  def file! media_type, desc = '', schema_hash = { type: File }
    body! media_type, desc, schema_hash
  end
  ```
  
  **Notice:** Each API can only declare a request body. 
  That is, all of the above methods you can only choose one of them.
  
  Media Type: We provide some [mapping](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/oas_objs/media_type_obj.rb) from symbols to real media-types.  
  
  schema_hash: As above (see param), but more than a `type` (schema type).
  
- response family methods (OAS - [Response Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#response-object))
  - `response` (`resp`)
  - `response_ref`
  - `default_response` (`dft_resp`)
  - `error_response` (`other_response`, `oth_resp`, `error`, `err_resp`): Are `response`'s aliases, should be used in the error response context.
  
  Define the responses for the API(operation).
  You can use the Response Object to link to request body that is defined at the components/responses by method response_ref().
  
  ```ruby
  # method signature
  response code, desc, media_type = nil, schema_hash = { }
  # usage
  response '200', 'query result export', :pdf, type: File

  # method signature
  response_ref code_compkey_hash
  # usage
  response_ref '700' => :RespComp, '800' => :RespComp
  ```
  
  **practice:** Combined with wrong class, automatically generate error responses. TODO
  
- security: TODO

- server: TODO
  
#### \>\> DSL methods inside apis_set'block ([code source](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl_inside_block.rb):: CtrlInfoObj )

(Here corresponds to OAS [Components Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#componentsObject))

These methods in the block describe the current controller, 
in other words, these methods eventually produce reusable components.

So, the following methods are used as above, except that you need to 
name the key of the component, and pass it as the first of argument list, like:

```ruby
query! :QueryCompUuid, :product_uuid, Integer, ...
```
This writing is feasible but not recommended, 
because component's key and parameter's name looks like the same level.
The recommended writing is:

```ruby
query! :QueryCompUuid => [:product_uuid, Integer, ...]
```
The DSL methods used to generate the components in this block are: 

- param family methods (except `param_ref`) (explained above)
- request_body family methods (except `body_ref`) (explained above)
- schema: define Schema Object component.
  
  ```ruby
  # method signature
  schema component_key, type, schema_hash
  # usage
  schema :Dog  => [ { id!: Integer, name: String }, dft: { id: 1, name: 'pet' } ]
  # advance usage
  schema :Dog => [{
                       id!: Integer,
                       name: { type: String, must_be: 'zhandao', desc: 'name' }
                   }, # this is schema type*
                   dft: { id: 1, name: 'pet' }]
  # or (unrecommended)
  schema :Dog, { id!: Integer, name: String }, dft: { id: 1, name: 'pet' }
  ```
  *: see: [Type](https://github.com/zhandao/zero-rails_openapi/blob//parameter.md#type)

### Generate JSON Documentation File

Initializer or Console, run:

```ruby
OpenApi.write_docs
```

Then the JSON files will be written to the directory you set. (Each API a file.)

### Use Swagger UI(very beautiful web page) to show your Documentation

Download [Swagger UI](https://github.com/swagger-api/swagger-ui) (version >= 2.3.0 support the OAS3) 
to your project,  
modify the default JSON file path(url) in the index.html 
(window.onload >> SwaggerUIBundle >> url).  
In order to use it, you may have to enable CORS, [see](https://github.com/swagger-api/swagger-ui#cors-support)

### Tricks

#### Trick1 - Write the DSL Somewhere Else

Does your documentation take too many lines?  
Do you want to separate documentation from business controller to simplify both?  
Very easy! Just use `ctrl_path`.

```ruby
# config/initializers/open_api.rb
# in your configure
root_controller: BaseDoc

# app/api_doc/base_doc.rb
require 'open_api/dsl'

class BaseDoc < Object
  include OpenApi::DSL
end

# app/api_doc/v1/examples_doc.rb
class V1::ExamplesDoc < BaseDoc
  ctrl_path 'api/v1/examples'
  
  open_api :index do
    # ...
  end
end
```

Notes: convention is the file name ends with `_doc.rb`

#### Trick2 - Global DRYing

Method `api_dry` is for DRY but its scope is limited to the current controller.

I have no idea of best practices, But you can look at this [file](https://github.com/zhandao/zero-rails_openapi/blob/masterdocumentation/examples/auto_gen_doc.rb).  
The implementation of the file is: do `api_dry` when inherits the base controller inside `inherited` method.

#### Trick3 - Auto Generate Description

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
`search field, allows：<br/>1/ name<br/>2/ creator,<br/>3/ category<br/>4/ price<br/>`

ZRO also allows you use Hash to define `enum`:
```ruby
query :view, String, enum: {
        'all goods (default)': :all,
        'only online':         :online,
        'only offline':        :offline,
        'expensive goods':     :get,
        'cheap goods':         :borrow,
    }
```
Read this [file](https://github.com/zhandao/zero-rails_openapi/blob/examples/auto_gen_desc.rb) to learn more.

#### Trick4 - Skip or Use parameters define in api_dry

Pass `skip: []` and `use: []` to `open_api` like following code:
```ruby
open_api :index, 'desc', builder: :index, skip: [ :Token ]
```

Look at this [file](https://github.com/zhandao/zero-rails_openapi/blob/examples/goods_doc.rb) to learn more.

#### Trick5 - Auto Generate index/show Actions's Responses Based on DB Schema

Use method `load_schema` in `api_dry`.

See this [file](https://github.com/zhandao/zero-rails_openapi/blob/examples/auto_gen_doc.rb#L51) for uasge information.


## Troubleshooting

- **You wrote document of the current API, but not find in the generated json file?**  
  Check your routing settings.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Zero-OpenApi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/zhandao/zero-rails_openapi/blob/master/CODE_OF_CONDUCT.md).
