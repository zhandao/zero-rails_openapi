require 'open_api/dsl/common_dsl'

module OpenApi
  module DSL
    class CtrlInfoObj < Hash
      include DSL::CommonDSL
      include DSL::Helpers

      def schema component_key, type, schema_hash# = { }
        (self[:schemas] ||= { })[component_key] = SchemaObj.new(type, schema_hash).process
      end
      arrow_enable :schema

      def example summary, example_hash
        # TODO
      end

      def param component_key, param_type, name, type, required, schema_hash = { }
        (self[:parameters] ||= { })[component_key] =
            ParamObj.new(name, param_type, type, required, schema_hash).process
      end

      def _param_agent component_key, name, type, schema_hash = { }
        param component_key,
              "#{@param_type}".delete('!'), name, type, (@param_type['!'] ? :req : :opt), schema_hash
      end
      arrow_enable :_param_agent

      def request_body component_key, required, media_type, desc = '', schema_hash = { }
        (self[:requestBodies] ||= { })[component_key] =
            RequestBodyObj.new(required, media_type, desc, schema_hash).process
      end

      def _request_body_agent component_key, media_type, desc = '', schema_hash = { }
        request_body component_key,
                     (@method_name['!'] ? :req : :opt), media_type, desc, schema_hash
      end
      arrow_enable :_request_body_agent

      arrow_enable :resp # alias_method 竟然也会指向旧的方法？
      arrow_enable :response


      def _process_objs
        self[:responses]&.each do |code, obj|
          self[:responses][code] = obj.process if obj.is_a?(ResponseObj)
        end
      end
    end
  end
end
