require 'open_api/dsl/api_info_obj'
require 'open_api/dsl/components'

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
        current_ctrl = @_ctrl_infos[:components] = Components.new
        current_ctrl.instance_exec(&block)
        current_ctrl.process_objs
      end

      def api action, summary = '', http: nil, skip: [ ], use: [ ], &block
        apis_tag if @_ctrl_infos.nil?
        # select the routing info (corresponding to the current method) from routing list.
        action_path = "#{@_ctrl_path ||= controller_path}##{action}"
        routes_info = ctrl_routes_list&.select { |api| api[:action_path].match?(/^#{action_path}$/) }&.first
        pp "[ZRO Warning] Routing mapping failed: #{@_ctrl_path}##{action}" and return if routes_info.nil?

        api = ApiInfoObj.new(action_path, skip: Array(skip), use: Array(use))
                        .merge! description: '', summary: summary, operationId: action, tags: [@_apis_tag],
                                parameters: [ ], requestBody: '',  responses: { },      security: [ ], servers: [ ]
        [action, :all].each { |blk_key| @_api_dry_blocks&.[](blk_key)&.each { |blk| api.instance_eval(&blk) } }
        api.param_use  = [ ] # `skip` and `use` only affect `api_dry`'s blocks
        api.param_skip = [ ]
        api.param_use = [ ] # `skip` and `use` only affect `api_dry`'s blocks
        api.instance_exec(&block) if block_given?
        api.process_objs
        api.delete_if { |_, v| v.blank? }

        path = (@_api_infos ||= { })[routes_info[:path]] ||= { }
        (http || routes_info[:http_verb]).split('|').each { |verb| path[verb] = api }
        api
      end

      # method could be symbol array, like: %i[ .. ]
      def api_dry action = :all, desc = '', &block
        @_api_dry_blocks ||= { }
        Array(action).each { |a| (@_api_dry_blocks[a.to_sym] ||= [ ]) << block }
      end

      def ctrl_routes_list
        Generator.routes_list[@_ctrl_path]
      end
    end
  end
end
