# ZRO: OpenApi 3 DocGenerator for Rails

Provide concise DSL for you to generate the OpenAPI Specification 3 (**OAS3**, formerly Swagger3) JSON file for Rails application, 
then you can use Swagger UI 3.2.0+ to show the documentation.

## Contributing

**Hi, here is ZhanDao, This gem was completed when I learned Ruby less than three months, 
I'm not sure if it has problem, but it may have a lot to improve.  
I'm looking forward to your issues and PRs, thanks!**

Currently, I think the most important TODO is the Unit Test (RSpec, I want is), 
but I dont have enough time now = ▽ =

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

OpenApi.configure do |c|
  # [REQUIRED] The output location where .json doc file will be written to.
  c.file_output_path = 'public/open_api'

  c.register_apis = {
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

For more detailed configuration: [open_api.rb](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/examples/open_api.rb)

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

#### \> [DSL Usage Example](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/examples/examples_controller.rb)

```ruby
class Api::V1::ExamplesController < Api::V1::BaseController
  apis_set 'ExamplesController\'s APIs' do
    schema :Dog           => [ { id!: Integer, name: String }, dft: { id: 1, name: 'pet' } ]
    query! :QueryCompUuid => [ :product_uuid, String, desc: 'product uuid' ]
    path!  :PathCompId    => [ :id, Integer, desc: 'user id' ]
    resp   :RespComp      => [ 'bad request', :json ]
    body!  :RqBodyComp    => [ :form ]
  end

  open_api_set %i[index show], 'common response' do
    response '567', 'query result export', :pdf, type: File
  end

  open_api :index, '(SUMMARY) this api blah blah ...' do
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

##### \>\> controller class methods ([source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl.rb))

- `apis_set` [Optional]

  ```ruby
  # method signature
  apis_set desc = '', external_doc_url = '', &block
  # usage
  apis_set 'ExamplesController\'s APIs' do
    # DSL for define components
  end
  ```
  desc and external_doc_url will be output to the tags[the current tag] (tag defaults to controller_name ), but are optional, 
  the focus is on the block, the DSL methods in the block will generate components.

- `open_api_set` [Optional]

  this method is for DRYing.
  
  ```ruby

  ```

- `open_api`

##### \>\> DSL methods inside *open_api* and *open_api_set*'s block ([source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl_inside_block.rb):: ApiInfoObj)

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

- param family methods (OAS - [Parameter Object](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#parameterObject))
  - `param`
  - `param_ref`
  - `header`, `path`, `query`, `cookie` and bang methods: `header!`, `path!`, `query!`, `cookie!`

  Define the parameters for the API(operation).
  You can use the Reference Object to link to parameters that are defined at the OpenAPI Object's components/parameters by method param_ref().

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
    header! :'X-Token', String
    query!  :done,      Boolean, must_be: false, default: true
```

  [**>> More About Param DSL <<**](https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/paramerer.md)


- request_body family methods
  - `request_body`
  - `body_ref`
  - `body` and bang `body!`
  - `form`, `form!`; `file`, `file!`
  
  
- response family methods
  - `response` (`resp`)
  - `response_ref`
  - `default_response` (`dft_resp`)
  - `error_response` (`other_response`, `oth_resp`, `error`, `err_resp`)
  
- security

- server
  
##### \>\> DSL methods inside apis_set'block ([code source](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/open_api/dsl_inside_block.rb):: CtrlInfoObj )

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
(explained above)

- param family methods (except `param_ref`)
- request_body family methods (except `body_ref`)



### Generate JSON Documentation File

Initializer or console, run:

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

## Troubleshooting

No trouble yet.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Zero-OpenApi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/zhandao/zero-rails_openapi/blob/master/CODE_OF_CONDUCT.md).
