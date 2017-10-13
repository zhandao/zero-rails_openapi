require 'open_api/dsl_inside_block'

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

      def apis_set desc = '', external_doc_url = '', &block
        @_ctrl_infos = { }
        # current `tag`, this means that tags is currently divided by controllers.
        tag = @_ctrl_infos[:tag] = { name: @_apis_tag ||= controller_name.camelize }
        tag[:description]  = desc if desc.present?
        tag[:externalDocs] = { description: 'ref', url: external_doc_url } if external_doc_url.present?

        current_ctrl = @_ctrl_infos[:components] = CtrlInfoObj.new
        current_ctrl.instance_eval &block if block_given?
      end

      def open_api method, summary = '', &block
        apis_set if @_ctrl_infos.nil?

        # select the routing info (corresponding to the current method) from the routing list.
        action_path = "#{@_ctrl_path ||= controller_path}##{method}"
        routes_info = ctrl_routes_list&.select { |api| api[:action_path].match? /^#{action_path}$/ }&.first
        puts "[zero-rails_openapi] Routing mapping failed: #{@_ctrl_path}##{method}" or return if routes_info.nil?

        # structural { path: { http_method:{ } } }, for Paths Object.
        path = (@_api_infos ||= { })[routes_info[:path]] ||= { }
        current_api = path[routes_info[:http_verb]] =
            ApiInfoObj.new(action_path)
                .merge! description: '', summary: summary, operationId: method, tags: [@_apis_tag],
                        parameters: [ ], requestBody: '', responses: { },
                        security: [ ], servers: [ ]

        current_api.tap do |it|
          [method, :all].each do |key| # blocks_store_key
            @_apis_blocks&.[](key)&.each { |blk| it.instance_eval &blk }
          end
          it.instance_eval &block if block_given?
          it.instance_eval { process_params }
          it.delete_if { |_, v| v.blank? }
        end
      end

      # For DRY; method could be symbol array
      def api_dry method = :all, desc = '', &block
        @_apis_blocks ||= { }
        if method.is_a? Array
          method.each { |m| (@_apis_blocks[m.to_sym] ||= [ ]) << block }
        else
          (@_apis_blocks[method.to_sym] ||= [ ]) << block
        end
      end

      def ctrl_routes_list
        @routes_list ||= Generator.generate_routes_list
        @routes_list[@_ctrl_path]
      end
    end
  end
end
