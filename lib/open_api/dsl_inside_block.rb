require 'oas_objs/schema_obj'
require 'oas_objs/param_obj'
require 'oas_objs/response_obj'
require 'oas_objs/request_body_obj'
require 'oas_objs/ref_obj'

module OpenApi
  module DSL
    module CommonDSL
      def arrow_writing_support
        proc do |args, executor|
          if args.count == 1 && args.first.is_a?(Hash)
            send(executor, args[0].keys.first, *args[0].values.first)
          else
            send(executor, *args)
          end
        end
      end

      %i[header header! path path! query query! cookie cookie!].each do |param_type|
        define_method param_type do |*args|
          @param_type = param_type
          _param_agent *args
        end
      end

      %i[body body!].each do |method|
        define_method method do |*args|
          @method_name = method
          _request_body_agent *args
        end
      end

      # code represents `component_key` when declare response component
      def _response code, desc, media_type = nil, schema_hash = { }
        (self[:responses] ||= { }).merge! ResponseObj.new(code, desc, media_type, schema_hash).process
      end

      def response *args
        arrow_writing_support.call(args, :_response)
      end

      def default_response desc, media_type = nil, schema_hash = { }
        response :default, desc, media_type, schema_hash
      end

      { # alias_methods mapping
          response:         %i[error_response  resp                     ],
          default_response: %i[dft_resp        dft_response             ],
          error_response:   %i[other_response  oth_resp  error  err_resp],
      }.each do |original_name, aliases|
        aliases.each do |alias_name|
          alias_method alias_name, original_name
        end
      end
    end # ----------------------------------------- end of CommonDSL




    class CtrlInfoObj < Hash
      include DSL::CommonDSL

      def _schema component_key, type, schema_hash = { }
        (self[:schemas] ||= { }).merge! component_key => SchemaObj.new(type, schema_hash).process
      end
      def schema *args
        arrow_writing_support.call(args, :_schema)
      end

      def param component_key, param_type, name, type, required, schema_hash = { }
        (self[:parameters] ||= { })
            .merge! component_key => ParamObj.new(name, param_type, type, required, schema_hash).process
      end

      def _param_agent *args
        arrow_writing_support.call(args, :_param_arg_agent)
      end

      def _param_arg_agent component_key, name, type, schema_hash = { }
        param component_key, "#{@param_type}".delete('!'), name, type,
              ("#{@param_type}".match?(/!/) ? :req : :opt), schema_hash
      end

      def request_body component_key, required, media_type, desc = '', schema_hash = { }
        self[:requestBodies] = { component_key => RequestBodyObj.new(required, media_type, desc, schema_hash).process }
      end

      def _request_body_agent *args
        arrow_writing_support.call(args, :_request_body_arg_agent)
      end

      def _request_body_arg_agent component_key, media_type, desc = '', schema_hash = { }
        request_body component_key, ("#{@method_name}".match?(/!/) ? :req : :opt), media_type, desc, schema_hash
      end
    end # ----------------------------------------- end of CtrlInfoObj




    class ApiInfoObj < Hash
      include DSL::CommonDSL

      attr_accessor :action_path
      def initialize(action_path)
        self.action_path = action_path
      end

      def this_api_is_invalid! explain = ''
        self[:deprecated] = true
      end
      alias_method :this_api_is_expired!,     :this_api_is_invalid!
      alias_method :this_api_is_unused!,      :this_api_is_invalid!
      alias_method :this_api_is_under_repair, :this_api_is_invalid!

      def desc desc, inputs_descs = { }
        @inputs_descs = inputs_descs
        self[:description] = desc
      end

      def param param_type, name, type, required, schema_hash = { }
        schema_hash[:desc] = @inputs_descs[name] if @inputs_descs&.[](name).present?
        (self[:parameters] ||= [ ]) << ParamObj.new(name, param_type, type, required, schema_hash).process
      end

      def _param_agent name, type, schema_hash = { }
        param "#{@param_type}".delete('!'), name, type, ("#{@param_type}".match?(/!/) ? :req : :opt), schema_hash
      end

      def param_ref component_key, *keys
        (self[:parameters] ||= [ ]).concat [component_key].concat(keys).map { |key| RefObj.new(:parameter, key).process }
      end

      def request_body required, media_type, desc = '', schema_hash = { }
        self[:requestBody] = RequestBodyObj.new(required, media_type, desc, schema_hash).process
      end

      def _request_body_agent media_type, desc = '', schema_hash = { }
        request_body ("#{@method_name}".match?(/!/) ? :req : :opt), media_type, desc, schema_hash
      end

      def body_ref component_key
        self[:requestBody] = RefObj.new(:requestBody, component_key).process
      end

      def response_ref code_compkey_hash
        code_compkey_hash.each do |code, component_key|
          (self[:responses] ||= { }).merge! code => RefObj.new(:response, component_key).process
        end
      end

      # 注意同时只能写一句 request body，包括 form 和 file
      def form desc = '', schema_hash = { }
        body :form, desc, schema_hash
      end
      def form! desc = '', schema_hash = { }
        body! :form, desc, schema_hash
      end
      def file media_type, desc = '', schema_hash = { type: File }
        body media_type, desc, schema_hash
      end
      def file! media_type, desc = '', schema_hash = { type: File }
        body! media_type, desc, schema_hash
      end

      def security scheme_name, requirements = [ ]
        (self[:security] ||= [ ]) << { scheme_name => requirements }
      end

      def server url, desc
        (self[:servers] ||= [ ]) << { url: url, description: desc }
      end
    end # ----------------------------------------- end of ApiInfoObj
  end
end
