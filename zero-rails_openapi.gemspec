
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "open_api/version"

Gem::Specification.new do |spec|
  spec.name          = "zero-rails_openapi"
  spec.version       = OpenApi::VERSION
  spec.authors       = ["zhandao"]
  spec.email         = ["x@skippingcat.com"]

  spec.summary       = %q{Generate the OpenAPI Specification 3 documentation for Rails application.}
  spec.description   = %q{Provide concise DSL for generating the OpenAPI Specification 3 (OAS3)
                         documentation JSON file for Rails application,
                         then you can use Swagger-UI 3.2.0+ to show the documentation.}
  spec.homepage      = "https://github.com/zhandao/zero-rails_openapi"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.15.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "rails", ">= 3"
  spec.add_runtime_dependency "activesupport", ">= 3"
end
