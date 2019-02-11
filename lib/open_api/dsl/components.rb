# frozen_string_literal: true

require 'open_api/dsl/helpers'

module OpenApi
  module DSL
    class Components < Hash
      include DSL::Helpers

      def initialize
        merge!(%i[ schemas responses	parameters examples requestBodies securitySchemes ].map { |k| [ k, { } ] }.to_h)
      end

      def schema component_key, type = nil, **schema_info
        schema = process_schema_input(type, schema_info, model: component_key)
        return Tip.schema_no_type(component_key) if schema[:illegal?]
        self[:schemas][component_key.to_s.to_sym] = (schema[:combined] or SchemaObj.new(schema[:info], { })).process
      end

      arrow_enable :schema

      def example component_key, examples_hash
        self[:examples][component_key] = ExampleObj.new(examples_hash, multiple: true).process
      end

      arrow_enable :example

      def param component_key, param_type, name, type, required, schema = { }
        schema = process_schema_input(type, schema)
        return Tip.param_no_type(name) if schema[:illegal?]
        self[:parameters][component_key] =
            ParamObj.new(name, param_type, type, required, schema[:combined] || schema[:info]).process
      end

      %i[ header header! path path! query query! cookie cookie! ].each do |param_type|
        define_method param_type do |component_key, name, type = nil, **schema|
          param component_key, param_type, name, type, (param_type['!'] ? :req : :opt), schema
        end

        arrow_enable param_type
      end

      def request_body component_key, required, media_type, data: { }, desc: '', **options
        cur = self[:requestBodies][component_key]
        cur = RequestBodyObj.new(required, desc) unless cur.is_a?(RequestBodyObj)
        self[:requestBodies][component_key] = cur.add_or_fusion(media_type, { data: data, **options })
      end

      %i[ body body! ].each do |method|
        define_method method do |component_key, media_type, data: { }, **options|
          request_body component_key, (method['!'] ? :req : :opt), media_type, data: data, **options
        end
      end

      arrow_enable :body
      arrow_enable :body!

      def response component_key, desc, media_type = nil, data: { }, type: nil
        self[:responses][component_key] = ResponseObj.new(desc) unless (self[:responses] ||= { })[component_key].is_a?(ResponseObj)
        self[:responses][component_key].add_or_fusion(desc, media_type, { data: type || data })
      end

      alias_method :resp,  :response
      alias_method :error, :response

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
        self.delete_if { |_, v| v.blank? }
      end
    end
  end
end
