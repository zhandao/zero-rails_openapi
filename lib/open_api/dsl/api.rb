# frozen_string_literal: true

require 'open_api/dsl/helpers'

module OpenApi
  module DSL
    class Api < Hash
      include DSL::Helpers

      attr_accessor :_all_params
      attr_accessor :action_path, :dry_skip, :dry_only, :dry_blocks, :dryed, :param_order

      def initialize(action_path = "", summary: nil, tags: [ ], id: nil)
        self.action_path = action_path
        self.dry_blocks  = [ ]
        self._all_params = { }
        self.merge!(
          summary: summary, operationId: id, tags: tags, description: "", parameters: [ ],
          requestBody: nil, responses: { }, callbacks: { }, links: { }, security: [ ], servers: [ ]
        )
      end

      def this_api_is_invalid!(*)
        self[:deprecated] = true
      end
      alias this_api_is_expired!      this_api_is_invalid!
      alias this_api_is_unused!       this_api_is_invalid!
      alias this_api_is_under_repair! this_api_is_invalid!

      def desc(desc)
        self[:description] = desc
      end
      alias description desc

      def dry(only: nil, skip: nil, none: false)
        return if dry_blocks.blank? || dryed

        self.dry_skip = Array(skip).compact.presence
        self.dry_only = none ? [:none] : Array(only).compact.presence
        dry_blocks.each { |blk| instance_eval(&blk) }
        self.dry_skip = self.dry_only = nil
        self.dryed = true
      end

      def param(param_type, name, type, required, schema = { })
        return if dry_skip&.include?(name) || dry_only&.exclude?(name)
        return unless (schema_obj = process_schema_input(type, schema, name))

        _all_params[name] = schema.is_a?(Hash) ? schema.merge(type:) : { type: } unless param_type["header"]
        override_or_append_to_parameters(
          ParamObj.new(name, param_type, type, required, schema_obj)
        )
      end
      alias parameter param

      # @!method query(name, type = nil, **schema)
      # @!method query!(name, type = nil, **schema)
      # @!method in_query(**params)
      # @!method in_query!(**params)
      %i[ header header! path path! query query! cookie cookie! ].each do |param_type|
        define_method(param_type) do |name, type = nil, **schema|
          param param_type, name, type, required?(param_type), schema
        end

        define_method("in_#{param_type}") do |params|
          params.each_pair do |param_name, schema|
            param param_type, param_name, nil, required?(param_type, param_name), schema
          end
        end
      end

      def param_ref(component_key, *keys)
        self[:parameters] += [component_key, *keys].map { |key| RefObj.new(:parameter, key) }
      end

      # options: `exp_params` and `examples`
      def request_body(required, media_type, data: { }, desc: "", **options)
        self[:requestBody] ||= RequestBodyObj.new(required, desc)
        self[:requestBody].absorb(media_type, { data:, **options })
        _all_params.merge!(data)
      end

      def body(media_type, data: { }, **) = request_body(:optional, media_type, data:, **)
      def body!(media_type, data: { }, **) = request_body(:required, media_type, data:, **)

      def json(data:, **) = body(:json, data:, **)
      def json!(data:, **) = body!(:json, data:, **)
      def form(data:, **) = body(:form, data:, **)
      def form!(data:, **) = body!(:form, data:, **)

      def data(name, type = nil, schema = { })
        schema[:type] = type if type.present?
        form data: { name => schema }
      end

      def body_ref(component_key)
        self[:requestBody] = RefObj.new(:requestBody, component_key)
      end

      def response(code, desc, media_type = nil, headers: { }, data: { }, **)
        self[:responses][code.to_s] ||= ResponseObj.new(desc)
        self[:responses][code.to_s].absorb(desc, media_type, headers:, data:, **)
      end

      alias_method :resp,  :response
      alias_method :error, :response

      def response_ref(code_and_compkey) # = { }
        code_and_compkey.each do |code, component_key|
          self[:responses][code.to_s] = RefObj.new(:response, component_key)
        end
      end

      def security_require(scheme_name, scopes: [ ])
        self[:security] << { scheme_name => scopes }
      end

      alias security  security_require
      alias auth      security_require
      alias auth_with security_require

      def callback(event_name, http_method, callback_url, &block)
        self[:callbacks].deep_merge!(
          CallbackObj.new(event_name, http_method, callback_url, &block).process
        )
      end

      def server(url, desc: "")
        self[:servers] << { url: url, description: desc }
      end

      def param_examples(exp_params = :all, examples_hash)
        exp_params = self[:parameters].map(&:name) if exp_params == :all
        self[:examples] = ExampleObj.new(examples_hash, exp_params, multiple: true).process
      end

      alias examples param_examples

      def run_dsl(dry: false, &block)
        instance_exec(&block) if block_given?
        dry() if dry

        self[:parameters].map!(&:process)
        self[:requestBody] = self[:requestBody].try(:process)
        self[:responses] = self[:responses].transform_values(&:process).sort.to_h
        self.delete_if { |_, v| v.blank? }
      end

      def all_params
        _all_params.transform_values do |t|
          if t.is_a?(Hash)
            t.key?(:type) ? t.merge!(type: t[:type].to_s.underscore) : { type: t }
          else
            { type: t.to_s.underscore }
          end
        end
      end

      private

        def override_or_append_to_parameters(param_obj)
          # The definition of the same name parameter will be override.
          index = self[:parameters].map(&:name).index(param_obj.name)
          index ? self[:parameters][index] = param_obj : self[:parameters] << param_obj
        end

        def required?(*passed)
          passed.join["!"] ? :required : :optional
        end
    end
  end
end
