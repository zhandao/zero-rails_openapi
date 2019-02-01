# frozen_string_literal: true

require 'open_api/dsl/api'
require 'open_api/dsl/components'

module OpenApi
  module DSL
    extend ActiveSupport::Concern
    
    class_methods do
      def oas
        @oas ||= { doc: { }, dry_blocks: { }, apis: { }, tag_name: try(:controller_name)&.camelize }
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
        structure = %i[ schemas responses	parameters examples requestBodies securitySchemes ].map { |k| [k, { }] }.to_h
        current_doc = Components.new.merge!(structure)
        current_doc.instance_exec(&block)
        current_doc.process_objs

        (oas[:doc][:components] ||= { }).deep_merge!(current_doc)
      end

      def api action, summary = '', id: nil, tag: nil, http: nil, skip: [ ], use: [ ], &block
        doc_tag if oas[:doc].blank?
        # select the routing info (corresponding to the current method) from routing list.
        action_path = "#{oas[:route_base] ||= controller_path}##{action}"
        routes = ctrl_routes_list&.select { |api| api[:action_path][/^#{action_path}$/].present? }
        return Tip.no_route(action_path) if routes.blank?

        api = Api.new(action_path, skip: Array(skip), use: Array(use))
                 .merge! description: '', summary: summary, operationId: id || "#{oas[:doc][:tag][:name]}_#{action.to_s.camelize}",
                         tags: [tag || oas[:doc][:tag][:name]], parameters: [ ], requestBody: '',  responses: { },  callbacks: { },
                         links: { }, security: [ ], servers: [ ]
        [action, :all].each { |blk_key| oas[:dry_blocks][blk_key]&.each { |blk| api.instance_eval(&blk) } }
        api.param_use = api.param_skip = [ ] # `skip` and `use` only affect `api_dry`'s blocks
        api.instance_exec(&block) if block_given?
        api.process_objs
        api.delete_if { |_, v| v.blank? }

        routes.each do |route|
          path = oas[:apis][route[:path]] ||= { }
          (http || route[:http_verb]).split('|').each { |verb| path[verb] = api }
        end

        api
      end

      def api_dry action = :all, desc = '', &block
        Array(action).each { |a| (oas[:dry_blocks][a.to_sym] ||= [ ]) << block }
      end

      def ctrl_routes_list
        Generator.routes_list[oas[:route_base]]
      end
    end
  end
end
