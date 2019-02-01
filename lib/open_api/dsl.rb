# frozen_string_literal: true

require 'open_api/dsl/api'
require 'open_api/dsl/components'

module OpenApi
  module DSL
    extend ActiveSupport::Concern
    
    class_methods do
      def oas
        @oas ||= { doc: { }, dry_blocks: { }, apis: { }, route_base: try(:controller_path),
                   tag_name: try(:controller_name)&.camelize }
      end

      def route_base path
        oas[:route_base] = path
        oas[:tag_name] = path.split('/').last.camelize
      end

      # APIs will be grouped by tags.
      def doc_tag name: nil, **tag_info #  description: ..., externalDocs: ...
        oas[:doc][:tag] = { name: name || oas[:tag_name], **tag_info }
      end

      def components &block
        doc_tag if oas[:doc].blank?
        (current_doc = Components.new).instance_exec(&block)
        current_doc.process_objs
        (oas[:doc][:components] ||= { }).deep_merge!(current_doc)
      end

      def api action, summary = '', id: nil, tag: nil, http: nil, skip: [ ], use: [ ], &block
        doc_tag if oas[:doc].blank?
        action_path = "#{oas[:route_base]}##{action}"
        routes = ctrl_routes_list&.select { |api| api[:action_path][/^#{action_path}$/].present? }
        return Tip.no_route(action_path) if routes.blank?

        tag = tag || oas[:doc][:tag][:name]
        api = Api.new(action_path, skip: Array(skip), use: Array(use))
                 .merge!(summary: summary, tags: [tag], operationId: id || "#{tag}_#{action.to_s.camelize}")
        _api_dry(api, action, tag)
        api.instance_exec(&block) if block_given?
        api.process_objs
        api.delete_if { |_, v| v.blank? }
        _set_apis(api, routes, http)
      end

      def api_dry action_or_tags = :all, &block
        Array(action_or_tags).each { |a| (oas[:dry_blocks][a.to_sym] ||= [ ]) << block }
      end

      def ctrl_routes_list
        Generator.routes_list[oas[:route_base]]
      end

      def _api_dry(api, action, tag)
        [action, tag, :all].each do |blk_key|
          oas[:dry_blocks][blk_key]&.each { |blk| api.instance_eval(&blk) }
        end
        api.param_use = api.param_skip = [ ] # `skip` and `use` only affect `api_dry`'s blocks
      end

      def _set_apis(api, routes, http)
        routes.each do |route|
          path = oas[:apis][route[:path]] ||= { }
          (http || route[:http_verb]).split('|').each { |verb| path[verb] = api }
        end
        api
      end
    end
  end
end
