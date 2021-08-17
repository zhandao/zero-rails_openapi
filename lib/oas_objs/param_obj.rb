# frozen_string_literal: true

require 'oas_objs/helpers'
require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    class ParamObj < Hash
      include Helpers

      attr_accessor :processed, :schema

      EXTRACTABLE_KEYS = %i[
        description examples style explode uniqueItems
      ].freeze

      def initialize(name, param_type, type, required, schema)
        self.processed = {
            name: name.to_s.delete('!').to_sym,
            in: param_type.to_s.delete('!'),
            required: required.to_s[/req/].present?
        }
        merge!(self.schema = schema)
      end

      def process
        processed[:schema] = schema.process
        EXTRACTABLE_KEYS.each { |key| extract_from_schema(key) }
        processed
      end

      def name
        processed[:name]
      end

      def extract_from_schema(key)
        processed[key] = processed[:schema].delete(key) if processed[:schema].key?(key)
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