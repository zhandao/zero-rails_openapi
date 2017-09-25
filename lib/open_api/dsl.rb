require 'open_api/dsl_inside_block'

module OpenApi
  module DSL
    def self.included(base)
      base.extend ClassMethods
    end

    # TODO: Doc-Block Comments
    module ClassMethods
      def apis_set desc = '', external_doc_url = '', &block
        @_api_infos, @_ctrl_infos = { }, { }
        # current `tag`, this means that tags is currently divided by controllers.
        tag = @_ctrl_infos[:tag] = { name: controller_name.camelize }
        tag[:description]  = desc if desc.present?
        tag[:externalDocs] = { description: 'ref', url: external_doc_url } if external_doc_url.present?

        current_ctrl = @_ctrl_infos[:components] = CtrlInfoObj.new
        current_ctrl.instance_eval &block if block_given?
      end

      def open_api method, summary = '', &block
        # select the routing info corresponding to the current method from the routing list.
        action_path = "#{controller_path}##{method}"
        routes_info = ctrl_routes_list.select { |api| api[:action_path].match? /^#{action_path}$/ }.first
        puts "[zero-rails_openapi] Routing mapping failed: #{controller_path}##{method}" or return if routes_info.nil?

        # structural { path: { http_method:{ } } }, for Paths Object.
        # it will be merged into :paths
        path = @_api_infos[routes_info[:path]] ||= { }
        current_api = path[routes_info[:http_verb]] =
            ApiInfoObj.new(action_path).merge!( summary: summary, operationId: method, tags: [controller_name.camelize] )

        current_api.tap do |it|
          it.instance_eval &block if block_given?
          [method, :all].each do |key| # blocks_store_key
            @_apis_blocks[key]&.each { |blk| it.instance_eval &blk }
          end
        end
      end

      # For DRY; method could be symbol array
      def open_api_set method = :all, desc = '', &block
        @_apis_blocks ||= { }
        if method.is_a? Array
          method.each { |m| (@_apis_blocks[m.to_sym] ||= [ ]) << block }
        else
          (@_apis_blocks[method.to_sym] ||= [ ]) << block
        end
      end

      def ctrl_routes_list
        @routes_list ||= Generator.generate_routes_list
        @routes_list[controller_path]
      end
    end
  end
end
