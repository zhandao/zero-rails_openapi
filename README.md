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
- [Usage - DSL](#usage-dsl)
- [Usage - Generate JSON documentation file](#usage-generate-json-documentation-file)
- [Usage - Use Swagger UI(very beautiful web page) to show your Documentation](#usage-use-swagger-uivery-beautiful-web-page-to-show-your-documentation)
- [Tricks](#tricks)
    - [Write DSL somewhere else](#trick1---write-the-dsl-somewhere-else)
    - [Global DRYing](#trick2---global-drying)
    - [Auto generate description](#trick3---auto-generate-description)
    - [Skip or Use parameters define in api_dry](#trick4---skip-or-use-parameters-define-in-api_dry)
    - [Atuo Generate index/show Actions's Responses Based on DB Schema](#trick5---auto-generate-indexshow-actionss-responses-based-on-db-schema)
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
# or
gem 'zero-rails_openapi', github: 'zhandao/zero-rails_openapi'
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
The following global configuration and component of OAS are allow to be set in the initializer: 
Server Object / Security Scheme Object / Security Requirement Object ...

In addition to direct use of Hash, you can also use Config DSL to configure:

```ruby
# config/initializers/open_api.rb
require 'open_api'

OpenApi::Config.tap do |c|
  c.instance_eval do
    api :homepage_api, root_controller: ApiDoc
    info version: '1.0.0', title: 'Homepage APIs'
  end
end
```

For more detailed configuration: [open_api.rb](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/open_api.rb)  
See all the settings you can configure: [config.rb](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/config.rb)

## Usage - DSL

### First of all, extend DSL for your base controller, for example:

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
  open_api :index, 'GET list' do
    query :page, Integer#, desc: 'page, greater than 1', range: { ge: 1 }, dft: 1
    query :rows, Integer#, desc: 'per page', range: { ge: 1 }, default: 10
  end
end
```

For more example, see [goods_doc.rb](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/goods_doc.rb), and
[examples_controller.rb](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/examples_controller.rb)

### DSL methods of controller ([source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl.rb))

#### `ctrl_path` (controller path) [optional]

  ```ruby
  # method signature
  ctrl_path(path)
  # usage
  ctrl_path 'api/v1/examples'
  ```
  It is optional because `ctrl_path` defaults to `controller_path`.
  
  [Here's a trick](#trick1---write-the-dsl-somewhere-else): Using `ctrl_path`, you can write the DSL somewhere else 
  to simplify the current controller.  

#### `apis_tag` [optional]

  ```ruby
  # method signature
  apis_tag(name: nil, desc: '', external_doc_url: '')
  # usage
  apis_tag name: 'ExampleTagName', desc: 'ExamplesController\'s APIs'
  ```
  This method allows you to set the Tag (which is a node of [OpenApi Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#openapi-object)).  
  
  desc and external_doc_url will be output to the tags[the current tag] (tag defaults to controller_name), but are optional. 

#### `components` [optional]

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
  open_api :action, 'summary' do
    query :doge, :DogSchema # to use a Schema component
    param_ref :UidQuery     # to use a Parameter component
    response_ref :BadRqResp # to use a Response component
  end
  ```
  Component can be used to simplify your DSL code (by using `*_ref` methods).
  
  Each RefObj you defined is associated with components through component key.
  We suggest that component keys should be camelized symbol.

#### `api_dry` [optional]

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
  
#### `open_api` [required]

  Define the specified API (controller action, in the following example is index).
  
  ```ruby
  # method signature
  open_api(action, summary = '', builder: nil, skip: [ ], use: [ ], &block)
  # usage
  open_api :index, '(SUMMARY) this api blah blah ...', builder: :index # block ...
  ```
  If you pass `builder`, and `generate_jbuilder_file` is set to `true` (in your initializer),
  ZRO will generate JBuilder file by using specified template called `index`.  
  About template settings, see: [open_api.rb](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/open_api.rb)
  
  `use` and `skip` options: to use or skip the parameters defined in `api_dry`.
  
  ```ruby
    open_api :show, 'summary', use: [:id] # => it will only take :id from DRYed result.
  ```

### DSL methods inside [open_api]() and [api_dry]()'s block

[source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl_inside_block.rb)::ApiInfoObj

These following methods in the block describe the specified API action: description, valid?,
parameters, request body, responses, securities, servers.

(Here corresponds to OAS [Operation Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#operationObject))

#### `this_api_is_invalid!`, its aliases:
  ```
  this_api_is_expired!
  this_api_is_unused!
  this_api_is_under_repair!
  ```

  ```ruby
  # method signature
  this_api_is_invalid! explain = ''
  # usage
  this_api_is_invalid! 'this api is expired!'
  ```
  
  Then `deprecated` of this API will be set to true.

#### `desc`: description for the current API and its inputs (parameters and request body)

  ```ruby
  # method signature
  desc desc, param_descs = { }
  # usage
  desc 'current API\'s description',
       id:    'desc of the parameter :id',
       email: 'desc of the parameter :email'
  ```

  You can of course describe the input in it's DSL method (like `query! :done ...` [this line](https://github.com/zhandao/zero-rails_openapi#-dsl-usage-example)), 
  but that will make it long and ugly. We recommend that unite descriptions in this place.
  
  In addition, when you want to dry the same parameters (each with a different description), it will be of great use.

#### `param` family methods (OAS - [Parameter Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#parameterObject))
  ```
  param
  param_ref
  header,  path,  query,  cookie
  header!, path!, query!, cookie!
  do_* by: { parameter_hashes }
  sort
  ```
  **The bang method(`!`) means it is required, so without `!` means it is optional. the same below.**

  Define the parameters for the API(operation).
  You can use the Reference Object to link to parameters that are defined at the components/parameters by method param_ref().

  ```ruby
  # method signature
  param param_type, name, type, required, schema_hash = { }
  # usage
  param :query, :page, Integer, :req,  range: { gt: 0, le: 5 }, desc: 'page',
        examples: { :right_input => 5 }
  
  # method signature
  param_ref component_key, *component_keys
  # usage
  param_ref :PathCompId
  param_ref :PathCompId, :QueryComp#, ...
  
  # method signature
  header  name, type, schema_hash = { }
  header! name, type, schema_hash = { }
  query!  name, type, schema_hash = { }
  # usage
  header! 'Token', String
  query!  :read,   Boolean, must_be: true, default: false

  # method signature
  do_query by:
  # usage
  do_query by: {
    :search_type => { type: String  },
        :export! => { type: Boolean }
  }
  # Same as below, but a little more succinctly
  query  :search_type, String
  query! :export, Boolean
  ```

  [**>> More About Param DSL <<**](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/parameter.md)

#### request_body family methods (OAS - [Request Body Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#requestBodyObject))
  ```
  request_body
  body_ref      # use ref obj to define the body
  body, body!   # alias of request_body
  form, form!   # define a multipart/form-data body
  file, file!   # define a File media-type body
  ```
  
  OpenAPI 3.0 uses the requestBody keyword to distinguish the payload from parameters.  
  Define the request body for the API (action),
  You can use the Reference Object to link to request body that is defined at the components/requestBodies by method `body_ref()`.
  
  ```ruby
  # method signature
  request_body required, media_type, desc = '', hash = { }
  # usage
  request_body :opt, :form, type: { id!: Integer, name: String }


  # method signature
  body_ref component_key
  # usage
  body_ref :Body


  # method signature
  body! media_type, desc = '', hash = { }
  # usage
  body :json
  
  
  # method implement
  def form desc = '', hash = { }
    body :form, desc, hash
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
      }


  # about `file`
  def file! media_type, desc = '', hash = { type: File }
    body! media_type, desc, hash
  end
  ```
  
  (1) **Notice:** Each API can only declare a request body. 
  That is, all of the above methods you can only choose one of them.  
  (2) Media Type: We provide some [mapping](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/oas_objs/media_type_obj.rb) from symbols to real media-types.  
  (3) schema_hash: As above (see param), it's just one more a `type` (schema type).
  (4) `examples` usage see [goods_doc](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/goods_doc.rb)
  
#### response family methods (OAS - [Response Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#response-object))
  - `response` (`resp`)
  - `response_ref`
  - `default_response` (`dft_resp`)
  - `error_response` (`other_response`, `oth_resp`, `error`, `err_resp`): Are `response`'s aliases, should be used in the error response context.
  - `override_response` # TODO
  
  Define the responses for the API(operation).
  You can use the Response Object to link to request body that is defined at the components/responses by method response_ref().
  
  ```ruby
  # method signature
  response code, desc, media_type = nil, hash = { }
  # usage
  response 200, 'query result export', :pdf, type: File

  # method signature
  response_ref code_compkey_hash
  # usage
  response_ref 700 => :RespComp, 800 => :RespComp
  ```
  
  (1) **practice:** Combined with wrong class, automatically generate error responses. TODO  
  (2) `examples` usage see [goods_doc](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/goods_doc.rb)
  
#### security: TODO

#### server: TODO
  
### DSL methods inside components'block ([code source](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl_inside_block.rb):: CtrlInfoObj )

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
  *: see: [Type](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/parameter.md#type)

## Usage - Generate JSON Documentation File

Initializer or Console, run:

```ruby
OpenApi.write_docs
```

Then the JSON files will be written to the directory you set. (Each API a file.)

## Usage - Use Swagger UI(very beautiful web page) to show your Documentation

Download [Swagger UI](https://github.com/swagger-api/swagger-ui) (version >= 2.3.0 support the OAS3) 
to your project,  
modify the default JSON file path(url) in the index.html 
(window.onload >> SwaggerUIBundle >> url).  
In order to use it, you may have to enable CORS, [see](https://github.com/swagger-api/swagger-ui#cors-support)

## Tricks

### Trick1 - Write the DSL Somewhere Else

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

### Trick2 - Global DRYing

Method `api_dry` is for DRY but its scope is limited to the current controller.

I have no idea of best practices, But you can look at this [file](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/auto_gen_doc.rb).  
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
Read this [file](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/auto_gen_desc.rb) to learn more.

### Trick4 - Skip or Use parameters define in api_dry

Pass `skip: []` and `use: []` to `open_api` like following code:
```ruby
open_api :index, 'desc', builder: :index, skip: [ :Token ]
```

Look at this [file](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/goods_doc.rb) to learn more.

### Trick5 - Auto Generate index/show Actions's Response-Types Based on DB Schema

Use method `load_schema` in `api_dry`.

See this [file](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/auto_gen_doc.rb#L51) for uasge information.


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
