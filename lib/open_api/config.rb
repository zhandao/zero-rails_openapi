# frozen_string_literal: true

require 'open_api/config_dsl'
require 'active_support/all'

module OpenApi
  module Config
    include ConfigDSL

    cattr_accessor :default_run_dry, default: false

    # [REQUIRED] The location where .json doc file will be output.
    cattr_accessor :file_output_path, default: 'public/open_api'

    cattr_accessor :doc_location, default: ['./app/**/*_doc.rb']

    cattr_accessor :rails_routes_file

    cattr_accessor :model_base

    # Everything about OAS3 is on https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md
    # Getting started: https://swagger.io/docs/specification/basic-structure/
    cattr_accessor :open_api_docs, default: { }

    cattr_accessor :file_format, default: 'binary'

    def self.docs
      open_api_docs
    end
  end
end
