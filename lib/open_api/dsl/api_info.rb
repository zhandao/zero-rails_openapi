require 'open_api/dsl/common_dsl'

module OpenApi
  module DSL
    class ApiInfo < Hash
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

      alias this_api_is_expired!      this_api_is_invalid!
      alias this_api_is_unused!       this_api_is_invalid!
      alias this_api_is_under_repair! this_api_is_invalid!

      def desc desc, param_descs = { }
        self.param_descs = param_descs
        self[:description] = desc
      end

      def param param_type, name, type, required, schema_info = { }
        return if param_skip.include?(name)
        return if param_use.present? && param_use.exclude?(name)

        schema_info[:desc]  ||= param_descs[name]
        schema_info[:desc!] ||= param_descs[:"#{name}!"]
        param_obj = ParamObj.new(name, param_type, type, required, schema_info)
        # The definition of the same name parameter will be overwritten
        fill_in_parameters(param_obj)
      end

      # [ header header! path path! query query! cookie cookie! ]
      def _param_agent name, type = nil, **schema_info
        schema = process_schema_info(type, schema_info)
        return puts '    ZRO'.red + " Syntax Error: param `#{name}` has no schema type!" if schema[:illegal?]
        param @param_type, name, schema[:type], @necessity, schema[:combined] || schema[:info]
      end

      # For supporting this: (just like `form '', data: { }` usage)
      #   do_query by: {
      #     :search_type => { type: String  },
      #         :export! => { type: Boolean }
      #   }
      %i[ header header! path path! query query! cookie cookie! ].each do |param_type|
        define_method "do_#{param_type}" do |by:, **common_schema|
          by.each do |param_name, schema|
            action = "#{param_type}#{param_name['!']}".sub('!!', '!')
            type, schema = schema.is_a?(Hash) ? [schema[:type], schema] : [schema, { }]
            args = [ param_name.to_s.delete('!').to_sym, type, schema.reverse_merge!(common_schema) ]
            send(action, *args)
          end
        end
      end

      def param_ref component_key, *keys
        self[:parameters] += [component_key, *keys].map { |key| RefObj.new(:parameter, key) }
      end

      # options: `exp_by` and `examples`
      def request_body required, media_type, data: { }, **options
        desc = options.delete(:desc) || ''
        self[:requestBody] = RequestBodyObj.new(required, desc) unless self[:requestBody].is_a?(RequestBodyObj)
        self[:requestBody].add_or_fusion(media_type, { data: data , **options })
      end

      # [ body body! ]
      def _request_body_agent media_type, data: { }, **options
        request_body @necessity, media_type, data: data, **options
      end

      def body_ref component_key
        self[:requestBody] = RefObj.new(:requestBody, component_key)
      end

      def form data:, **options
        body :form, data: data, **options
      end

      def form! data:, **options
        body! :form, data: data, **options
      end

      def data name, type = nil, schema_info = { }
        schema_info[:type] = type if type.present?
        form data: { name => schema_info }
      end

      def file media_type, data: { type: File }, **options
        body media_type, data: data, **options
      end

      def file! media_type, data: { type: File }, **options
        body! media_type, data: data, **options
      end

      def response_ref code_compkey_hash
        code_compkey_hash.each { |code, component_key| self[:responses][code] = RefObj.new(:response, component_key) }
      end

      def security_require scheme_name, scopes: [ ]
        self[:security] << { scheme_name => scopes }
      end

      alias security  security_require
      alias auth      security_require
      alias need_auth security_require

      def server url, desc: ''
        self[:servers] << { url: url, description: desc }
      end

      def order *param_names
        self.param_order = param_names
        # be used when `api_dry`
        self.param_use = param_order if param_use.blank?
        self.param_skip = param_use - param_order
      end

      def param_examples exp_by = :all, examples_hash
        exp_by = self[:parameters].map(&:name) if exp_by == :all
        self[:examples] = ExampleObj.new(examples_hash, exp_by).process
      end

      alias examples param_examples

      def process_objs
        self[:parameters].map!(&:process)
        self[:parameters].sort_by! { |param| param_order.index(param[:name]) || Float::INFINITY } if param_order.present?

        self[:requestBody] = self[:requestBody].try(:process)
        self[:responses].each { |code, response| self[:responses][code] = response.process }
      end
    end
  end
end
