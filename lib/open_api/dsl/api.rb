# frozen_string_literal: true

require 'open_api/dsl/helpers'

module OpenApi
  module DSL
    class Api < Hash
      include DSL::Helpers

      attr_accessor :action_path, :dry_skip, :dry_only, :dry_blocks, :dryed, :param_order

      def initialize(action_path = '', summary: nil, tags: [ ], id: nil)
        self.action_path = action_path
        self.dry_blocks  = [ ]
        self.merge!(summary: summary, operationId: id, tags: tags, description: '', parameters: [ ],
                    requestBody: nil, responses: { }, callbacks: { }, links: { }, security: [ ], servers: [ ])
      end

      def this_api_is_invalid!(*)
        self[:deprecated] = true
      end

      alias this_api_is_expired!      this_api_is_invalid!
      alias this_api_is_unused!       this_api_is_invalid!
      alias this_api_is_under_repair! this_api_is_invalid!

      def desc desc
        self[:description] = desc
      end

      alias description desc

      def dry only: nil, skip: nil, none: false
        return if dry_blocks.blank? || dryed
        self.dry_skip = skip && Array(skip)
        self.dry_only = none ? [:none] : only && Array(only)
        dry_blocks.each { |blk| instance_eval(&blk) }
        self.dry_skip = self.dry_only = nil
        self.dryed = true
      end

      def param param_type, name, type, required, schema = { }
        return if dry_skip&.include?(name) || dry_only&.exclude?(name)

        return unless schema = process_schema_input(type, schema, name)
        param_obj = ParamObj.new(name, param_type, type, required, schema)
        # The definition of the same name parameter will be overwritten
        index = self[:parameters].map(&:name).index(param_obj.name)
        index ? self[:parameters][index] = param_obj : self[:parameters] << param_obj
      end

      alias parameter param

      %i[ header header! path path! query query! cookie cookie! ].each do |param_type|
        define_method param_type do |name, type = nil, **schema|
          param param_type, name, type, (param_type['!'] ? :req : :opt), schema
        end

        define_method "in_#{param_type}" do |params|
          params.each_pair do |param_name, schema|
            param param_type, param_name, nil, (param_type['!'] || param_name['!'] ? :req : :opt), schema
          end
        end
      end

      def param_ref component_key, *keys
        self[:parameters] += [component_key, *keys].map { |key| RefObj.new(:parameter, key) }
      end

      # options: `exp_params` and `examples`
      def request_body required, media_type, data: { }, desc: '', **options
        (self[:requestBody] ||= RequestBodyObj.new(required, desc)).absorb(media_type, { data: data , **options })
      end

      def body_ref component_key
        self[:requestBody] = RefObj.new(:requestBody, component_key)
      end

      %i[ body body! ].each do |method|
        define_method method do |media_type, data: { }, **options|
          request_body (method['!'] ? :req : :opt), media_type, data: data, **options
        end
      end

      def form data:, **options
        body :form, data: data, **options
      end

      def form! data:, **options
        body! :form, data: data, **options
      end

      def data name, type = nil, schema = { }
        schema[:type] = type if type.present?
        form data: { name => schema }
      end

      def response code, desc, media_type = nil, headers: { }, data: { }, **options
        (self[:responses][code.to_s] ||= ResponseObj.new(desc)).absorb(desc, media_type, headers: headers, data: data, **options)
      end

      alias_method :resp,  :response
      alias_method :error, :response

      def response_ref code_and_compkey # = { }
        code_and_compkey.each { |code, component_key| self[:responses][code] = RefObj.new(:response, component_key) }
      end

      def security_require scheme_name, scopes: [ ]
        self[:security] << { scheme_name => scopes }
      end

      alias security  security_require
      alias auth      security_require
      alias auth_with security_require

      def callback event_name, http_method, callback_url, &block
        self[:callbacks].deep_merge! CallbackObj.new(event_name, http_method, callback_url, &block).process
      end

      def server url, desc: ''
        self[:servers] << { url: url, description: desc }
      end

      def param_examples exp_params = :all, examples_hash
        exp_params = self[:parameters].map(&:name) if exp_params == :all
        self[:examples] = ExampleObj.new(examples_hash, exp_params, multiple: true).process
      end

      alias examples param_examples

      def run_dsl(dry: false, &block)
        instance_exec(&block) if block_given?
        dry() if dry

        self[:parameters].map!(&:process)
        self[:requestBody] = self[:requestBody].try(:process)
        self[:responses].each { |code, response| self[:responses][code] = response.process }
        self[:responses] = self[:responses].sort.to_h
        self.delete_if { |_, v| v.blank? }
      end
    end
  end
end
