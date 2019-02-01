# frozen_string_literal: true

require 'open_api/dsl/common_dsl'

module OpenApi
  module DSL
    class Components < Hash
      include DSL::CommonDSL
      include DSL::Helpers

      def schema component_key, type = nil, **schema_info
        schema = process_schema_info(type, schema_info, model: component_key)
        return puts '    ZRO'.red + " Syntax Error: component schema `#{component_key}` has no type!" if schema[:illegal?]
        self[:schemas][component_key.to_s.to_sym] = (schema[:combined] or SchemaObj.new(type = schema[:info], { })).process
      end

      arrow_enable :schema

      def example component_key, examples_hash
        self[:examples][component_key] = ExampleObj.new(examples_hash, multiple: true).process
      end

      arrow_enable :example

      def param component_key, param_type, name, type, required, schema_info = { }
        self[:parameters][component_key] = ParamObj.new(name, param_type, type, required, schema_info).process
      end

      # [ header header! path path! query query! cookie cookie! ]
      def _param_agent component_key, name, type = nil, **schema_info
        schema = process_schema_info(type, schema_info)
        return puts '    ZRO'.red + " Syntax Error: param `#{name}` has no schema type!" if schema[:illegal?]
        param component_key, @param_type, name, schema[:type], @necessity, schema[:combined] || schema[:info]
      end

      arrow_enable :_param_agent

      def request_body component_key, required, media_type, data: { }, desc: '', **options
        cur = self[:requestBodies][component_key]
        cur = RequestBodyObj.new(required, desc) unless cur.is_a?(RequestBodyObj)
        self[:requestBodies][component_key] = cur.add_or_fusion(media_type, { data: data, **options })
      end

      # [ body body! ]
      def _request_body_agent component_key, media_type, data: { }, **options
        request_body component_key, @necessity, media_type, data: data, **options
      end

      arrow_enable :_request_body_agent

      arrow_enable :resp
      arrow_enable :response

      def security_scheme scheme_name, other_info# = { }
        other_info[:description] = other_info.delete(:desc) if other_info[:desc]
        self[:securitySchemes][scheme_name] = other_info
      end

      arrow_enable :security_scheme

      alias auth_scheme security_scheme

      def base_auth scheme_name, other_info = { }
        security_scheme scheme_name, { type: 'http', scheme: 'basic', **other_info }
      end

      arrow_enable :base_auth

      def bearer_auth scheme_name, format = 'JWT', other_info = { }
        security_scheme scheme_name, { type: 'http', scheme: 'bearer', bearerFormat: format, **other_info }
      end

      arrow_enable :bearer_auth

      def api_key scheme_name, field:, in: 'header', **other_info
        _in = binding.local_variable_get(:in)
        security_scheme scheme_name, { type: 'apiKey', name: field, in: _in, **other_info }
      end

      arrow_enable :api_key

      def process_objs
        self[:requestBodies].each { |key, body| self[:requestBodies][key] = body.process }
        self[:responses].each { |code, response| self[:responses][code] = response.process }
      end
    end
  end
end
