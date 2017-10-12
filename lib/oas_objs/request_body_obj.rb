require 'oas_objs/media_type_obj'
require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://swagger.io/docs/specification/describing-request-body/
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#requestBodyObject
    class RequestBodyObj < Hash
      include Helpers

      attr_accessor :processed, :media_type
      def initialize(required, media_type, desc, schema_hash)
        self.media_type = MediaTypeObj.new(media_type, schema_hash)
        self.processed  = { required: required.to_s.match?(/req/), description: desc }
      end

      def process
        assign(media_type.process).to_processed 'content'
        processed
      end
    end
  end
end


__END__

Request Body Examples
A request body with a referenced model definition.

{
  "description": "user to add to the system",
  "content": {
    "multipart/form-data": {
      "schema": {
        "$ref": "#/components/schemas/User"
      },
      "examples": {
          "user" : {
            "summary": "User Example",
            "externalValue": "http://foo.bar/examples/user-example.json"
          }
        }
    },
    "*/*": {
      "examples": {
        "user" : {
            "summary": "User example in other format",
            "externalValue": "http://foo.bar/examples/user-example.whatever"
        }
      }
    }
  }
}
