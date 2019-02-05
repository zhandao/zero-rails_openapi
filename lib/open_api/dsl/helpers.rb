# frozen_string_literal: true

require 'oas_objs/schema_obj'
require 'oas_objs/combined_schema'
require 'oas_objs/param_obj'
require 'oas_objs/response_obj'
require 'oas_objs/request_body_obj'
require 'oas_objs/ref_obj'
require 'oas_objs/example_obj'
require 'oas_objs/callback_obj'

module OpenApi
  module DSL
    module Helpers
      extend ActiveSupport::Concern

      def load_schema(model) # TODO: test
        return unless Config.model_base && model.try(:superclass) == Config.model_base
        model.columns.map do |column|
            type = column.sql_type_metadata.type.to_s.camelize
            type = 'DateTime' if type == 'Datetime'
            [ column.name.to_sym, Object.const_get(type) ]
          end.to_h rescue ''
      end

      def _combined_schema(one_of: nil, all_of: nil, any_of: nil, not: nil, **other)
        input = (_not = binding.local_variable_get(:not)) || one_of || all_of || any_of
        CombinedSchema.new(one_of: one_of, all_of: all_of, any_of: any_of, _not: _not) if input
      end

      def process_schema_input(schema_type, schema, model: nil)
        schema = { type: schema } unless schema.is_a?(Hash)
        combined_schema = _combined_schema(schema)
        type = schema[:type] ||= schema_type
        {
            illegal?: type.nil? && combined_schema.nil?,
            combined: combined_schema,
            info: load_schema(model) || schema,
            type: type
        }
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
          send(executor, *args)
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
