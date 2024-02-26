
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'open_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'zero-rails_openapi'
  spec.version       = OpenApi::VERSION
  spec.authors       = ['zhandao']
  spec.email         = ['x@skippingcat.com']

  spec.summary       = 'Concise DSL for generating OpenAPI3 documentation.'
  spec.description   = 'Concise DSL for generating OpenAPI Specification 3 (OAS3) JSON documentation for Rails application.'
  spec.homepage      = 'https://github.com/zhandao/zero-rails_openapi'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'pry'

  spec.add_dependency 'colorize'
  spec.add_dependency 'activesupport', '>= 4.1'
  spec.add_dependency 'rails', '>= 4.1'

  # spec.post_install_message = ""
end
