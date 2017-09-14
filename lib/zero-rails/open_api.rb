require "zero-rails/open_api/version"
require "zero-rails/open_api/config"
require "zero-rails/open_api/generator"
require "zero-rails/open_api/dsl"

module ZeroRails
  module OpenApi
    include Config
    include Generator
  end
end
