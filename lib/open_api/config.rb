require 'open_api/config_dsl'
require 'active_support/all'

module OpenApi
  module Config
    include ConfigDSL

    # [REQUIRED] The location where .json doc file will be output.
    cattr_accessor :file_output_path do
      'public/open_api'
    end

    cattr_accessor :generate_doc do
      true
    end

    cattr_accessor :doc_location do
      ['./app/**/*_doc.rb']
    end

    cattr_accessor :rails_routes_file do
      nil
    end

    cattr_accessor :active_record_base do
      nil
    end

    # Everything about OAS3 is on https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md
    # Getting started: https://swagger.io/docs/specification/basic-structure/
    cattr_accessor :open_api_docs do
      {
      #     # [REQUIRED] At least one doc.
      #     zero_rails: {
      #         # [REQUIRED] ZRO will scan all the descendants of the base_doc_class, and then generate their docs.
      #         base_doc_class: ApplicationController,
      #
      #         # [REQUIRED] Info Object: The info section contains API information
      #         info: {
      #             # [REQUIRED] The title of the application.
      #             title: 'Zero Rails Apis',
      #             # [REQUIRED] The version of the OpenAPI document
      #             # (which is distinct from the OpenAPI Specification version or the API implementation version).
      #             version: '0.0.1'
      #         }
      #     }
      }
    end

    cattr_accessor :file_format do
      'binary'
    end

    def self.docs
      open_api_docs
    end
  end
end
