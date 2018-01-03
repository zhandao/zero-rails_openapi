require 'oas_objs/helpers'
require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    class ParamObj < Hash
      include Helpers

      attr_accessor :processed, :schema

      def initialize(name, param_type, type, required, schema)
        self.processed = {
            name: name,
            in: param_type,
            required: required.to_s.match?(/req/)
        }
        self.schema = schema.is_a?(CombinedSchema) ? schema : SchemaObj.new(type, schema)
        merge! schema
      end

      def process
        assign(desc).to_processed :description
        assign(schema.process).to_processed :schema
        processed
      end

      def desc
        return self[:desc] || self[:description] if (self[:desc!] || self[:description!]).blank?
        schema.__desc # not a copy of __desc, means desc() will change if schema.__desc changes.
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