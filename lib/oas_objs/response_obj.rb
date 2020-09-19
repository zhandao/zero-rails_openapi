# frozen_string_literal: true

require 'oas_objs/media_type_obj'
require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#responseObject
    class ResponseObj < Hash
      include Helpers

      attr_accessor :processed, :media_types, :headers

      def initialize(desc)
        self.media_types = [ ]
        self.headers = { }
        self.processed   = { description: desc }
      end

      def absorb(desc, media_type, headers: { }, **media_hash)
        self.processed[:description] = desc if desc.present?
        self.headers.merge!(headers)
        media_types << MediaTypeObj.new(media_type, **media_hash)
        self
      end

      def process
        content = media_types.map(&:process).reduce({ }, &fusion)
        processed[:content] = content if content.present?
        _headers = headers.map do |name, schema|
          schema = schema.is_a?(Hash) ? schema : { type: schema }
          [ name, HeaderObj.new(schema.delete(:desc), schema).process ]
        end.to_h
        processed[:headers] = _headers if _headers.present?
        processed
      end
    end
  end
end


__END__

Response Object Examples

Response of an array of a complex type:

{
  "description": "A complex object array response",
  "content": {
    "application/json": {
      "schema": {
        "type": "array",
        "items": {
          "$ref": "#/components/schemas/VeryComplexType"
        }
      }
    }
  }
}
