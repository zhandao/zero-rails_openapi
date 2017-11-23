require "open_api/version"
require "open_api/config"
require "open_api/generator"
require "open_api/dsl"

module OpenApi
  include Generator

  cattr_accessor :paths_index do
    { }
  end

  cattr_accessor :docs do
    { }
  end
end
