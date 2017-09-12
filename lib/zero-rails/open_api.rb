require "zero-rails/open_api/config"
require "zero-rails/open_api/generator"
# require 'zero-rails/open_api/dsl'
require "zero-rails/open_api/version"

module ZeroRails
  module OpenApi
    include Config
    include Generator
    # include DSL
  end
end
