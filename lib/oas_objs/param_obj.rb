# frozen_string_literal: true

require 'oas_objs/helpers'
require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    class ParamObj < Hash
      include Helpers

      attr_accessor :processed, :schema

      def initialize(name, param_type, type, required, schema)
        self.processed = {
            name: name.to_s.delete('!').to_sym,
            in: param_type.to_s.delete('!'),
            required: required.to_s[/req/].present?
        }
        self.schema = schema.is_a?(CombinedSchema) ? schema : SchemaObj.new(type, schema)
        merge!(schema)
      end

      def process
        processed[:schema] = schema.process
        desc = schema.processed[:description]
        processed[:description] = desc if desc
        processed
      end

      def name
        processed[:name]
      end
    end
  end
end


__END__

Parameter Object Examples
A header parameter with an array of 64 bit integer numbers:

{
  "name": "token",
  "in": "header",
  "description": "token to be passed as a header",
  "required": true,
  "schema": {
    "type": "array",
    "items": {
      "type": "integer",
      "format": "int64"
    }
  },
  "style": "simple"
}