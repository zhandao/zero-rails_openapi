require 'oas_objs/schema_obj'
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
      def response code, desc, media_type = nil, hash = { }
        (self[:responses] ||= { })[code] = ResponseObj.new(desc, media_type, hash)
      end

      def default_response desc, media_type = nil, hash = { }
        response :default, desc, media_type, hash
      end

      { # alias_methods mapping
          response:         %i[ error_response  resp                      ],
          default_response: %i[ dft_resp        dft_response              ],
          error_response:   %i[ other_response  oth_resp  error  err_resp ],
      }.each do |original_name, aliases|
        aliases.each do |alias_name|
          alias_method alias_name, original_name
        end
      end
    end
  end
end
