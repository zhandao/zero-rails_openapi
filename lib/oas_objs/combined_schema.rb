# frozen_string_literal: true

module OpenApi
  module DSL
    # https://swagger.io/docs/specification/data-models/oneof-anyof-allof-not/
    # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#schemaObject
    class CombinedSchema < Hash
      include Helpers

      attr_accessor :processed, :mode, :schemas

      def initialize(combined_schema)
        combined_schema.delete_if { |_, v| v.nil? }
        self.mode = combined_schema.keys.first.to_s.camelize(:lower).to_sym
        self.schemas = combined_schema.values.first
      end

      def process
        self.processed = {
            mode =>
                schemas.map do |schema|
                  type = schema.is_a?(Hash) ? schema[:type] : schema
                  schema = { } unless schema.is_a?(Hash)
                  SchemaObj.new(type, schema).process
                end
        }
      end
    end
  end
end

__END__

Inside schema:

"oneOf": [
  {
    "$ref": "#components/schemas/DogSchema"
  },
  {
    "type": "string"
  },
  {
    "type": "integer"
  }
]
