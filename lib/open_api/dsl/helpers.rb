module OpenApi
  module DSL
    module Helpers
      def self.included(base)
        base.extend ClassMethods
      end

      def load_schema(model)
        # About `show_attrs`, see:
        #   (1) BuilderSupport module: https://github.com/zhandao/zero-rails/blob/master/app/models/concerns/builder_support.rb
        #   (2) config in model: https://github.com/zhandao/zero-rails/tree/master/app/models/good.rb
        #   (3) jbuilder file: https://github.com/zhandao/zero-rails/blob/mster/app/views/api/v1/goods/index.json.jbuilder
        # in a word, BuilderSupport let you control the `output fields and nested association infos` very easily.
        if model&.respond_to? :show_attrs
          columns = model.columns.map(&:name).map(&:to_sym)
          model&.show_attrs&.map do |attr|
            if columns.include? attr
              index = columns.index attr
              type = model.columns[index].sql_type_metadata.type.to_s.camelize
              type = 'DateTime' if type == 'Datetime'
              { attr => Object.const_get(type) }
            elsif attr.match? /_info/
              # TODO: 如何获知关系是 many？因为不能只判断结尾是否 ‘s’
              assoc_model = Object.const_get(attr.to_s.split('_').first.singularize.camelize)
              { attr => load_schema(assoc_model) }
            end rescue next
          end
        else
          model&.columns&.map do |column|
            name = column.name.to_sym
            type = column.sql_type_metadata.type.to_s.camelize
            type = 'DateTime' if type == 'Datetime'
            { name => Object.const_get(type) }
          end
        end&.compact&.reduce({ }, :merge)
      end

      # Arrow Writing:
      #   response :RespComponent => [ '200', 'success', :json ]
      # It is equivalent to:
      #   response :RespComponent, '200', 'success', :json
      # But I think, in the definition of a component,
      #   the key-value (arrow) writing is easy to understand.
      def arrow_writing_support
        proc do |args, executor|
          _args = args.size == 1 && args.first.is_a?(Hash) ? args[0].to_a.flatten : args
          send executor, *_args
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
