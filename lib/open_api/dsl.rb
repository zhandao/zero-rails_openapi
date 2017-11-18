require 'open_api/dsl/api_info_obj'
require 'open_api/dsl/ctrl_info_obj'

module OpenApi
  module DSL
    def self.included(base)
      base.extend ClassMethods
    end

    # TODO: Doc-Block Comments
    module ClassMethods
      def ctrl_path path
        @_ctrl_path = path
        @_apis_tag  = path.split('/').last.camelize
      end

      def apis_tag name: nil, desc: '', external_doc_url: ''
        # current `tag`, this means that tags is currently divided by controllers.
        @_apis_tag = name if name.present?
        @_apis_tag ||= controller_name.camelize
        tag = (@_ctrl_infos = { })[:tag] = { name: @_apis_tag }
        tag[:description]  = desc if desc.present?
        tag[:externalDocs] = { description: 'ref', url: external_doc_url } if external_doc_url.present?
      end

      def components &block
        apis_tag if @_ctrl_infos.nil?
        current_ctrl = @_ctrl_infos[:components] = CtrlInfoObj.new
        current_ctrl.instance_eval(&block)
        current_ctrl._process_objs
      end

      def open_api method, summary = '', builder: nil, skip: [ ], use: [ ], &block
        apis_tag if @_ctrl_infos.nil?

        # select the routing info (corresponding to the current method) from routing list.
        action_path = "#{@_ctrl_path ||= controller_path}##{method}"
        routes_info = ctrl_routes_list&.select { |api| api[:action_path].match? /^#{action_path}$/ }&.first
        pp "[ZRO Warning] Routing mapping failed: #{@_ctrl_path}##{method}" and return if routes_info.nil?
        Generator.generate_builder_file(action_path, builder) if builder.present?

        # structural { #path: { #http_method:{ } } }, for pushing into Paths Object.
        path = (@_api_infos ||= { })[routes_info[:path]] ||= { }
        current_api = path[routes_info[:http_verb]] =
            ApiInfoObj.new(action_path, skip: Array(skip), use: Array(use))
                .merge! description: '', summary: summary, operationId: method, tags: [@_apis_tag],
                        parameters: [ ], requestBody: '',  responses: { },      security: [ ], servers: [ ]

        current_api.tap do |api|
          [method, :all].each do |key| # blocks_store_key
            @_apis_blocks&.[](key)&.each { |blk| api.instance_eval(&blk) }
          end
          api.param_use = [ ] # skip 和 use 是对 dry 块而言的
          api.instance_eval(&block) if block_given?
          api._process_objs
          api.delete_if { |_, v| v.blank? }
        end
      end

      # method could be symbol array, like: %i[ .. ]
      def api_dry method = :all, desc = '', &block
        @_apis_blocks ||= { }
        if method.is_a? Array
          method.each { |m| (@_apis_blocks[m.to_sym] ||= [ ]) << block }
        else
          (@_apis_blocks[method.to_sym] ||= [ ]) << block
        end
      end

      def ctrl_routes_list
        Generator.routes_list[@_ctrl_path]
      end
    end
  end
end
