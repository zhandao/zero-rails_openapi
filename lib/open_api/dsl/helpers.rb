module OpenApi
  module DSL
    module Helpers
      def self.included(base)
        base.extend ClassMethods
      end

      # :nocov:
      def load_schema(model)
        # About `show_attrs`, see:
        #   (1) BuilderSupport module: https://github.com/zhandao/zero-rails/blob/master/app/models/concerns/builder_support.rb
        #   (2) config in model: https://github.com/zhandao/zero-rails/tree/master/app/models/good.rb
        #   (3) jbuilder file: https://github.com/zhandao/zero-rails/blob/mster/app/views/api/v1/goods/index.json.jbuilder
        # In a word, BuilderSupport let you control the `output fields and nested association infos` very easily.
        if model.respond_to? :show_attrs
          _load_schema_based_on_show_attr(model)
        else
          model.columns.map { |column| _type_mapping(column) }
        end.compact.reduce({ }, :merge!) rescue ''
      end

      def _type_mapping(column)
        type = column.sql_type_metadata.type.to_s.camelize
        type = 'DateTime' if type == 'Datetime'
        { column.name.to_sym => Object.const_get(type) }
      end

      def _load_schema_based_on_show_attr(model)
        columns = model.column_names.map(&:to_sym)
        model.show_attrs.map do |attr|
          if columns.include?(attr)
            index = columns.index(attr)
            _type_mapping(model.columns[index])
          elsif attr.match?(/_info/)
            # TODO: 如何获知关系是 many？因为不能只判断结尾是否 ‘s’
            assoc_model = Object.const_get(attr.to_s.split('_').first.singularize.camelize)
            { attr => load_schema(assoc_model) }
          end rescue next
        end
      end
      # :nocov:

      def fill_in_parameters(param_obj)
        name = param_obj.processed[:name]
        index = self[:parameters].map { |p| p.processed[:name] if p.is_a?(ParamObj) }.index(name)
        index.present? ? self[:parameters][index] = param_obj : self[:parameters] << param_obj
      end

      # Arrow Writing:
      #   response :RespComponent => [ '200', 'success', :json ]
      # It is equivalent to:
      #   response :RespComponent, '200', 'success', :json
      # But I think, in the definition of a component,
      #   the key-value (arrow) writing is easy to understand.
      def arrow_writing_support
        proc do |args, executor|
          _args = (args.size == 1 && args.first.is_a?(Hash)) ? args[0].to_a.flatten : args
          send(executor, *_args)
        end
      end

      module ClassMethods
        def arrow_enable method
          alias_method "_#{method}".to_sym, method
          define_method method do |*args|
            arrow_writing_support.call(args, "_#{method}")
          end
        end
      end
    end
  end
end
