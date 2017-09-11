
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "zero/openapi_rails/version"

Gem::Specification.new do |spec|
  spec.name          = "zero-openapi_rails"
  spec.version       = Zero::OpenapiRails::VERSION
  spec.authors       = ["zhandao"]
  spec.email         = ["x@skippingcat.com"]

  spec.summary       = %q{Generate the OpenAPI Specification JSON file for (Zero) Rails application.}
  spec.description   = %q{Provide a very concise DSL for you to generate the OpenAPI Specification(Swagger 3)
                         JSON file for (Zero) Rails application, then you can use Swagger-UI 3.2.0+ to show the documentation.}
  spec.homepage      = "skippingcat.com"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16.a"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
