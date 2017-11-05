require 'oas_objs/media_type_obj'
require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#responseObject
    class ResponseObj < Hash
      include Helpers

      attr_accessor :processed, :code, :media_type
      def initialize(desc, media_type, schema_hash)
        @schema_hash = schema_hash
        @mt = media_type
        self.code       = code.to_s
        self.media_type = MediaTypeObj.new(media_type, schema_hash)
        self.processed  = { description: desc }
      end

      def process
        assign(media_type.process).to_processed 'content'
        processed
      end

      def override type_hash
        @schema_hash[:type].merge!(type_hash)
        self.media_type = MediaTypeObj.new(@mt, @schema_hash)
        self
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