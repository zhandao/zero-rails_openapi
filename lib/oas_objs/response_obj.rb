require 'oas_objs/media_type_obj'
require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#responseObject
    class ResponseObj < Hash
      include Helpers

      attr_accessor :processed, :media_types
      def initialize(desc)
        self.media_types = [ ]
        self.processed   = { description: desc }
      end

      def add_or_fusion(media_type, hash)
        media_types << MediaTypeObj.new(media_type, hash)
        self
      end

      def process
        assign(media_types.map(&:process).reduce({ }, &fusion)).to_processed 'content'
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