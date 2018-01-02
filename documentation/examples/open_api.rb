require 'open_api'

OpenApi::Config.tap do |c|
  # Config DSL
  c.instance_eval do
    open_api :zero_rails, base_doc_class: ApiDoc
    info version: '0.0.1', title: 'Zero Rails APIs', description: 'API documentation of Zero-Rails Application.'
    server 'http://localhost:3000', desc: 'Main (production) server'
    server 'http://localhost:3000', desc: 'Internal staging server for testing'
    bearer_auth :Token
    global_auth :Token
  end

  # [REQUIRED] The location where .json doc file will be output.
  c.file_output_path = 'public/open_api'

  # [Optional] Use this txt instead of running `rails routes`.
  # c.rails_routes_file = 'config/routes.txt'

  # Everything about OAS3 is on https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md
  # Getting started: https://swagger.io/docs/specification/basic-structure/
  c.open_api_docs = {
      blog_api: {
          # [REQUIRED] ZRO will scan all the descendants of the base_doc_class, then generate their docs.
          base_doc_class: ApiController,

          # [REQUIRED] Info Object: The info section contains API information
          info: {
              # [REQUIRED] The title of the application.
              title: 'Zero Rails APIs',
              # Description of the application.
              description: 'API documentation of Zero-Rails Application. <br/>' \
                           'Optional multiline or single-line Markdown-formatted description ' \
                           'in [CommonMark](http://spec.commonmark.org/) or `HTML`.',
              # A URL to the Terms of Service for the API. MUST be in the format of a URL.
              # termsOfService: 'http://example.com/terms/',
              # Contact Object: The contact information for the exposed API.
              contact: {
                  # The identifying name of the contact person/organization.
                  name: 'API Support',
                  # The URL pointing to the contact information. MUST be in the format of a URL.
                  url: 'http://www.github.com',
                  # The email address of the contact person/organization. MUST be in the format of an email address.
                  email: 'x@y.z'
              },
              # License Object: The license information for the exposed API.
              license: {
                  # [REQUIRED] The license name used for the API.
                  name: 'Apache 2.0',
                  # A URL to the license used for the API. MUST be in the format of a URL.
                  url: 'http://www.apache.org/licenses/LICENSE-2.0.html'
              },
              # [REQUIRED] The version of the OpenAPI document
              # (which is distinct from the OpenAPI Specification version or the API implementation version).
              version: '1.0.0'
          },

          # An array of Server Objects, which provide connectivity information to a target server.
          # If the servers property is not provided, or is an empty array,
          #   the default value would be a Server Object with a url value of /.
          # https://swagger.io/docs/specification/api-host-and-base-path/
          #   The servers section specifies the API server and base URL.
          #   You can define one or several servers, such as production and sandbox.
          servers: [
              {
                  # [REQUIRED] A URL to the target host.
                  # This URL supports Server Variables and MAY be relative,
                  #   to indicate that the host location is relative to the location where
                  #   the OpenAPI document is being served.
                  url: 'http://localhost:3000',
                  # An optional string describing the host designated by the URL.
                  description: 'Optional server description, e.g. Main (production) server'
              },{
                  url: 'http://localhost:3001',
                  description: 'Optional server description, e.g. Internal staging server for testing'
              }
          ],

          # Authentication
          #   The securitySchemes and security keywords are used to describe the authentication methods used in your API.
          #   https://swagger.io/docs/specification/authentication/
          # Security Scheme Object: An object to hold reusable Security Scheme Objects.
          securitySchemes: {
              ApiKeyAuth: { type: 'apiKey', name: 'server_token', in: 'query' },
              Token: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }
          },
          # Security Requirement Object
          #   A declaration of which security mechanisms can be used across the API.
          #   The list of values includes alternative security requirement objects that can be used.
          #   Only one of the security requirement objects need to be satisfied to authorize a request.
          #   Individual operations can override this definition.
          # see: https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#securityRequirementObject
          global_security: [{ ApiKeyAuth: [] }, { Token: [] }],
      }
  }

end

Object.const_set('Boolean', 'boolean') # Support `Boolean` writing in DSL

OpenApi.write_docs generate_files: !Rails.env.production?


__END__

(1) all the description:
    CommonMark(http://spec.commonmark.org/) syntax MAY be used for rich text representation.
(2) all the url could be URL template(?):
    Variable substitutions will be made when a variable is named in {brackets}.
    variables: Map Object, A map between a variable name and its value, is used for substitution in the URL template.
    variables example: https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#server-object-example
