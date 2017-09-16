require 'active_support/ordered_options'
require 'zero-rails/open_api/param_info_obj' # TODO: Why???

module ZeroRails
  module OpenApi
    module DSL
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def controller_description desc = '', external_doc_url = '', &block
          @_api_infos  ||= { }
          @_ctrl_infos ||= { }
          # current `tag`, this means that tags is currently divided by controllers.
          tag = @_ctrl_infos[:tag] = {name: controller_path.camelize }
          tag[:description] = desc if desc.present?
          tag[:externalDocs] = { description: 'ref', url: external_doc_url } if external_doc_url.present?

          schemas = @_ctrl_infos[:components_schemas] = CtrlInfoObj.new
          schemas.instance_eval &block  if block_given?
        end
        alias_method :ctrl_desc, :controller_description
        alias_method :apis_desc, :controller_description

        def open_api method, summary = '', &block
          # select the routing info corresponding to the current method from the routing list.
          routes_info = ctrl_routes_list.select { |api| api[:ctrl_action].split('#').last.match? /^#{method}$/ }.first
          puts "[zero-rails_openapi] Routing mapping failed: #{controller_path}##{method}" or return if routes_info.nil?

          # structural { path: { http_method:{ } } }, for Paths Object.
          # it will be merged into :paths
          path = @_api_infos[routes_info[:path]] ||= { }
          current_api = path[routes_info[:http_verb]] =
              ApiInfoObj.new.merge!({ summary: summary, operationId: method, tags: [controller_path.camelize] })
          current_api.instance_eval &block  if block_given?
        end

        def ctrl_routes_list
          @routes_list ||= Generator.generate_routes_list
          @routes_list[controller_path]
        end
      end


      class CtrlInfoObj < ActiveSupport::OrderedOptions

      end

      class ApiInfoObj < ActiveSupport::OrderedOptions

        def this_api_is_invalid! explain = ''
          self[:deprecated] = true
        end
        alias_method :this_api_is_expired!,      :this_api_is_invalid!
        alias_method :this_api_is_unused!,       :this_api_is_invalid!
        alias_method :this_api_is_under_repair!, :this_api_is_invalid!

        def desc desc
          self[:description] = desc
        end

        def param param_type, name, type, required, info_hash = { }
          param = ParamInfoObj.new(name, param_type, type, required).merge info_hash
          param.process and (self[:parameters] ||= [ ]) << param.processed
        end

        [:header,  :path,  :query,  :cookie,
         :header!, :path!, :query!, :cookie!].each do |param_type|
          define_method param_type do |name, type, info_hash = { }|
            param "#{param_type}".delete('!'), name, type, (param_type.to_s.match?(/!/) ? :req : :opt), info_hash
          end
        end

        def security

        end

        def server url, desc
          self[:servers] ||= []
          self[:servers] << { url: url, description: desc }
        end

        def response

        end

        def error_response

        end
        alias_method :error, :error_response
      end
    end
  end
end
