require 'open_api/dsl/common_dsl'

module OpenApi
  module DSL
    class ApiInfoObj < Hash
      include DSL::CommonDSL
      include DSL::Helpers

      attr_accessor :action_path, :param_skip, :param_use, :param_descs, :param_order

      def initialize(action_path, skip: [ ], use: [ ])
        self.action_path = action_path
        self.param_skip  = skip
        self.param_use   = use
        self.param_descs = { }
      end

      def this_api_is_invalid! explain = ''
        self[:deprecated] = true
      end

      alias this_api_is_expired!     this_api_is_invalid!
      alias this_api_is_unused!      this_api_is_invalid!
      alias this_api_is_under_repair this_api_is_invalid!

      def desc desc, param_descs = { }
        self.param_descs = param_descs
        self[:description] = desc
      end

      def param param_type, name, type, required, schema_hash = { }
        return if param_skip.include?(name)
        return if param_use.present? && param_use.exclude?(name)

        _t = nil
        schema_hash[:desc]  = _t if (_t = param_descs[name]).present?
        schema_hash[:desc!] = _t if (_t = param_descs["#{name}!".to_sym]).present?

        param_obj = ParamObj.new(name, param_type, type, required, schema_hash)
        # The definition of the same name parameter will be overwritten
        fill_in_parameters(param_obj)
      end

      # For supporting this: (just like `form '', data: { }` usage)
      #   do_query by: {
      #     :search_type => { type: String  },
      #         :export! => { type: Boolean }
      #   }
      %i[ header header! path path! query query! cookie cookie! ].each do |param_type|
        define_method "do_#{param_type}" do |by:|
          by.each do |key, value|
            args = [ key.dup.to_s.delete('!').to_sym, value.delete(:type), value ]
            key.to_s['!'] ? send("#{param_type}!", *args) : send(param_type, *args)
          end
        end unless param_type.to_s['!']
      end

      def _param_agent name, type = nil, one_of: nil, all_of: nil, any_of: nil, not: nil, **schema_hash
        (schema_hash = type) and (type = type.delete(:type)) if type.is_a?(Hash) && type.key?(:type)
        type = schema_hash[:type] if type.nil?

        combined_schema = one_of || all_of || any_of || (_not = binding.local_variable_get(:not))
        schema_hash = CombinedSchema.new(one_of: one_of, all_of: all_of, any_of: any_of, _not: _not) if combined_schema
        param "#{@param_type}".delete('!'), name, type, (@param_type['!'] ? :req : :opt), schema_hash
      end

      def param_ref component_key, *keys
        self[:parameters].concat([component_key].concat(keys).map { |key| RefObj.new(:parameter, key).process })
      end

      # options: `exp_by` and `examples`
      def request_body required, media_type, data: { }, **options
        desc = options.delete(:desc) || ''
        self[:requestBody] = RequestBodyObj.new(required, desc) unless self[:requestBody].is_a?(RequestBodyObj)
        self[:requestBody].add_or_fusion(media_type, options.merge(data: data))
      end

      def _request_body_agent media_type, data: { }, **options
        request_body (@method_name['!'] ? :req : :opt), media_type, data: data, **options
      end

      def body_ref component_key
        self[:requestBody] = RefObj.new(:requestBody, component_key).process
      end

      def response_ref code_compkey_hash
        code_compkey_hash.each do |code, component_key|
          self[:responses][code] = RefObj.new(:response, component_key).process
        end
      end

      def form data:, **options
        body :form, data: data, **options
      end

      def form! data:, **options
        body! :form, data: data, **options
      end

      def data name, type = nil, schema_hash = { }
        schema_hash[:type] = type if type.present?
        form data: { name => schema_hash }
      end

      def file media_type, data: { type: File }, **options
        body media_type, data: data, **options
      end

      def file! media_type, data: { type: File }, **options
        body! media_type, data: data, **options
      end

      def security_require scheme_name, scopes: [ ]
        self[:security] << { scheme_name => scopes }
      end

      alias security  security_require
      alias auth      security_require
      alias need_auth security_require

      def server url, desc
        self[:servers] << { url: url, description: desc }
      end

      def order *param_names
        self.param_order = param_names
        self.param_use = param_order if param_use.blank?
        self.param_skip = param_use - param_order
      end

      def param_examples exp_by = :all, examples_hash
        process_objs
        exp_by = self[:parameters].map { |p| p[:name] } if exp_by == :all
        self[:examples] = ExampleObj.new(examples_hash, exp_by).process
      end

      alias examples param_examples


      def process_objs
        self[:parameters]&.each_with_index do |p, index|
          self[:parameters][index] = p.process if p.is_a?(ParamObj)
        end

        # Parameters sorting
        self[:parameters].clone.each do |p|
          self[:parameters][param_order.index(p[:name]) || -1] = p
        end if param_order.present?

        self[:requestBody] = self[:requestBody].try :process

        self[:responses]&.each do |code, obj|
          self[:responses][code] = obj.process if obj.is_a?(ResponseObj)
        end
      end
    end
  end
end
