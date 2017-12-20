module OpenApi
  module DSL
    # https://swagger.io/docs/specification/data-models/oneof-anyof-allof-not/
    # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#schemaObject
    class CombinedSchema < Hash
      attr_accessor :processed

      def initialize(combined_schema)
        self.processed = { }

        combined_schema.delete_if { |_, v| v.nil? }
        @mode = combined_schema.keys.first.to_s.sub('_not', 'not').camelize(:lower).to_sym
        @schemas = combined_schema.values.first
      end

      def process(options = { inside_desc: false })
        processed[@mode] = @schemas.map do |schema|
          type = schema.is_a?(Hash) ? schema[:type] : schema
          schema = { } unless schema.is_a?(Hash)
          SchemaObj.new(type, schema).process(options)
        end
        processed
      end
    end
  end
end
