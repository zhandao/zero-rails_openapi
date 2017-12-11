require 'open_api/dsl/common_dsl'

module OpenApi
  module DSL
    class Components < Hash
      include DSL::CommonDSL
      include DSL::Helpers

      def schema component_key, type = nil, one_of: nil, all_of: nil, any_of: nil, not: nil, **schema_hash
        (schema_hash = type) and (type = type.delete(:type)) if type.is_a?(Hash) && type.key?(:type)
        type ||= schema_hash[:type]
        type ||= load_schema component_key if component_key.try(:superclass) == Config.active_record_base || ApplicationRecord

        combined_schema = (_not = binding.local_variable_get(:not)) || one_of || all_of || any_of
        combined_schema = CombinedSchema.new(one_of: one_of, all_of: all_of, any_of: any_of, _not: _not) if combined_schema
        (self[:schemas] ||= { })[component_key.to_s.to_sym] = combined_schema&.process || SchemaObj.new(type, schema_hash).process
      end
      arrow_enable :schema

      def example component_key, examples_hash
        (self[:examples] ||= { })[component_key] = ExampleObj.new(examples_hash).process
      end
      arrow_enable :example

      def param component_key, param_type, name, type, required, schema_hash = { }
        (self[:parameters] ||= { })[component_key] = ParamObj.new(name, param_type, type, required, schema_hash).process
      end

      def _param_agent component_key, name, type = nil, one_of: nil, all_of: nil, any_of: nil, not: nil, **schema_hash
        (schema_hash = type) and (type = type.delete(:type)) if type.is_a?(Hash) && type.key?(:type)
        type = schema_hash[:type] if type.nil?

        combined_schema = one_of || all_of || any_of || (_not = binding.local_variable_get(:not))
        schema_hash = CombinedSchema.new(one_of: one_of, all_of: all_of, any_of: any_of, _not: _not) if combined_schema
        param component_key,
              "#{@param_type}".delete('!'), name, type, (@param_type['!'] ? :req : :opt), schema_hash
      end
      arrow_enable :_param_agent

      def request_body component_key, required, media_type, desc = '', schema_hash = { }
        cur = (self[:requestBodies] ||= { })[component_key]
        cur = RequestBodyObj.new(required, desc) unless cur.is_a?(RequestBodyObj)
        self[:requestBodies][component_key] = cur.add(media_type, schema_hash)
      end

      def _request_body_agent component_key, media_type, desc = '', schema_hash = { }
        request_body component_key,
                     (@method_name['!'] ? :req : :opt), media_type, desc, schema_hash
      end
      arrow_enable :_request_body_agent

      arrow_enable :resp # alias_method 竟然也会指向旧的方法？
      arrow_enable :response

      def security_scheme scheme_name, other_info# = { }
        other_info[:description] = other_info.delete(:desc) if other_info[:desc]
        (self[:securitySchemes] ||= { })[scheme_name] = other_info
      end
      arrow_enable :security_scheme

      alias auth_scheme security_scheme

      def base_auth scheme_name, other_info = { }
        security_scheme scheme_name, { type: 'http', scheme: 'basic' }.merge(other_info)
      end
      arrow_enable :base_auth

      def bearer_auth scheme_name, format = 'JWT', other_info = { }
        security_scheme scheme_name, { type: 'http', scheme: 'bearer', bearerFormat: format }.merge(other_info)
      end
      arrow_enable :bearer_auth

      def api_key scheme_name, field:, in:, **other_info
        _in = binding.local_variable_get(:in)
        security_scheme scheme_name, { type: 'apiKey', name: field, in: _in }.merge(other_info)
      end
      arrow_enable :api_key

      def _process_objs
        self[:requestBodies]&.each do |key, obj|
          self[:requestBodies][key] = obj.process
        end

        self[:responses]&.each do |code, obj|
          self[:responses][code] = obj.process if obj.is_a?(ResponseObj)
        end
      end
    end
  end
end
