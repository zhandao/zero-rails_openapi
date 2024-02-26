# frozen_string_literal: true

require 'oas_objs/schema_obj'
require 'oas_objs/combined_schema'
require 'oas_objs/param_obj'
require 'oas_objs/response_obj'
require 'oas_objs/request_body_obj'
require 'oas_objs/ref_obj'
require 'oas_objs/example_obj'
require 'oas_objs/callback_obj'
require 'oas_objs/header_obj'

module OpenApi
  module DSL
    module Helpers
      extend ActiveSupport::Concern

      def _combined_schema(one_of: nil, all_of: nil, any_of: nil, not: nil, **other)
        input = (_not = binding.local_variable_get(:not)) || one_of || all_of || any_of
        CombinedSchema.new(one_of: one_of, all_of: all_of, any_of: any_of, not: _not) if input
      end

      def process_schema_input(schema_type, schema, name)
        if schema.is_a?(Hash)
          schema[:type] ||= schema_type
        else
          schema = { type: schema }
        end
        combined_schema = _combined_schema(**schema)
        return Tip.param_no_type(name) if schema[:type].nil? && combined_schema.nil?
        combined_schema || SchemaObj.new(schema[:type], schema)
      end

      # Arrow Writing:
      #   response :RespComponent => [ '200', 'success', :json ]
      # It is equivalent to:
      #   response :RespComponent, '200', 'success', :json
      # But I think, in the definition of a component,
      #   the key-value (arrow) writing is more easier to understand.
      def arrow_writing_support
        proc do |args, executor|
          args = (args.size == 1 && args.first.is_a?(Hash)) ? args[0].to_a.flatten : args

          if !executor.in?(%w[ _example _security_scheme _base_auth _bearer_auth ]) && args.last.is_a?(Hash)
            send(executor, *args[0..-2], **args[-1])
          else
            send(executor, *args)
          end
        end
      end

      class_methods do
        def arrow_enable method
          alias_method :"_#{method}", method
          define_method method do |*args|
            arrow_writing_support.call(args, "_#{method}")
          end
        end
      end
    end
  end
end
