# More Information: https://github.com/zhandao/zero-rails_openapi/blob/master/documentation/examples/open_api.rb
OpenApi::Config.tap do |c|
  c.instance_eval do
    open_api :zro, base_doc_class: ApiDoc
    info version: '0.0.1', title: 'APIs', desc: 'API documentation of Zero-Rails Application.'
    server 'http://localhost:3000', desc: 'Main (production) server'
    server 'http://localhost:3000', desc: 'Internal staging server for testing'
    bearer_auth :Token
    global_auth :Token
  end

  c.file_output_path = 'spec/support'

  # c.doc_location = [ 'spec/support/*_doc.rb' ]

  c.rails_routes_file = 'spec/support/routes.txt'
end
