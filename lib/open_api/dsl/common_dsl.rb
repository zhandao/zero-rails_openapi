require 'oas_objs/schema_obj'
require 'oas_objs/combined_schema'
require 'oas_objs/param_obj'
require 'oas_objs/response_obj'
require 'oas_objs/request_body_obj'
require 'oas_objs/ref_obj'
require 'oas_objs/example_obj'
require 'open_api/dsl/helpers'

module OpenApi
  module DSL
    module CommonDSL
      %i[ header header! path path! query query! cookie cookie! ].each do |param_type|
        define_method param_type do |*args|
          @param_type = param_type
          _param_agent *args
        end
      end

      %i[ body body! ].each do |method|
        define_method method do |*args|
          @method_name = method
          _request_body_agent *args
        end
      end

      # `code`: when defining components, `code` means `component_key`
      def response code, desc, media_type = nil, data: { }, type: nil
        self[:responses][code] = ResponseObj.new(desc) unless (self[:responses] ||= { })[code].is_a?(ResponseObj)
        self[:responses][code].add_or_fusion(media_type, { data: type || data })
      end

      alias_method :resp,  :response
      alias_method :error, :response
    end
  end
end
