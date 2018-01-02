require 'open_api/dsl/api_info'
require 'open_api/dsl/components'

module OpenApi
  module DSL
    def self.included(base)
      base.extend ClassMethods
    end

    # TODO: Doc-Block Comments
    module ClassMethods
      def route_base path
        @route_base = path
        @doc_tag    = path.split('/').last.camelize
      end

      def doc_tag name: nil, desc: '', external_doc_url: nil
        # apis will group by the tags.
        @doc_tag = name if name.present?
        @doc_tag ||= controller_name.camelize
        tag = (@doc_info = { })[:tag] = { name: @doc_tag }
        tag[:description]  = desc if desc.present?
        tag[:externalDocs] = { description: 'ref', url: external_doc_url } if external_doc_url
      end

      def components &block
        doc_tag if @doc_info.nil?
        current_doc = @doc_info[:components] = Components.new
        current_doc.instance_exec(&block)
        current_doc.process_objs
      end

      def api action, summary = '', http: http_method = nil, skip: [ ], use: [ ], &block
        doc_tag if @doc_info.nil?
        # select the routing info (corresponding to the current method) from routing list.
        action_path = "#{@route_base ||= controller_path}##{action}"
        routes = ctrl_routes_list&.select { |api| api[:action_path].match?(/^#{action_path}$/) }
        pp "[ZRO Warning] Routing mapping failed: #{@route_base}##{action}" and return if routes.blank?

        api = ApiInfo.new(action_path, skip: Array(skip), use: Array(use))
                     .merge! description: '', summary: summary, operationId: action, tags: [@doc_tag],
                             parameters: [ ], requestBody: '',  responses: { },      security: [ ], servers: [ ]
        [action, :all].each { |blk_key| @zro_dry_blocks&.[](blk_key)&.each { |blk| api.instance_eval(&blk) } }
        api.param_use = api.param_skip = [ ] # `skip` and `use` only affect `api_dry`'s blocks
        api.instance_exec(&block) if block_given?
        api.process_objs
        api.delete_if { |_, v| v.blank? }

        routes.each do |route|
          path = (@api_info ||= { })[route[:path]] ||= { }
          (http || route[:http_verb]).split('|').each { |verb| path[verb] = api }
        end

        api
      end

      # method could be symbol array, like: %i[ .. ]
      def api_dry action = :all, desc = '', &block
        @zro_dry_blocks ||= { }
        Array(action).each { |a| (@zro_dry_blocks[a.to_sym] ||= [ ]) << block }
      end

      def ctrl_routes_list
        Generator.routes_list[@route_base]
      end
    end
  end
end
