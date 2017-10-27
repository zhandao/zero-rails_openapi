require 'open_api/config_dsl'

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

    # Everything about OAS3 is on https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md
    # Getting started: https://swagger.io/docs/specification/basic-structure/
    cattr_accessor :register_docs do
      {
          # [REQUIRED] At least one doc.
          zero_rails: {
              # [REQUIRED] ZRO will scan all the descendants of the root_controller, and then generate their docs.
              root_controller: ApplicationController,

              # [REQUIRED] Info Object: The info section contains API information
              info: {
                  # [REQUIRED] The title of the application.
                  title: 'Zero Rails Apis',
                  # [REQUIRED] The version of the OpenAPI document
                  # (which is distinct from the OpenAPI Specification version or the API implementation version).
                  version: '0.0.1'
              }
          }
      }
    end

    cattr_accessor :is_options do
      %w[ email phone password uuid uri url time date ]
    end

    cattr_accessor :dft_file_format do
      'binary'
    end

    cattr_accessor :generate_jbuilder_file do
      false
    end

    cattr_accessor :overwrite_jbuilder_file do
      false
    end

    cattr_accessor :jbuilder_templates do
      {
          index: (
          <<-FILE
json.partial! 'api/base', total: @data.count

json.data do
  # @data = @data.page(@_page).per(@_rows) if @_page || @_rows
  # json.array! @data do |datum|
  json.array! @data.page(@_page).per(@_rows) do |datum|
    json.(datum, *datum.show_attrs) if datum.present?
  end
end
          FILE
          ),

          show: (
          <<-FILE
json.partial! 'api/base', total: 1

json.data do
  json.array! [ @data ] do |datum|
    json.(datum, *datum.show_attrs) if datum.present?
  end
end
          FILE
          ),

          success: (
          <<-FILE
json.partial! 'api/success'
          FILE
          ),

          success_or_not: (
          <<-FILE
unless @status
  # @_code, @_msg = @error_info.present? ? @error_info : ApiError.action_failed.info
end

json.partial! 'api/base', total: 0
json.data ''
          FILE
          ),
      }
    end

    def self.docs
      register_docs
    end
  end
end
