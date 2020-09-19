# frozen_string_literal: true

require 'oas_objs/media_type_obj'
require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://swagger.io/docs/specification/describing-request-body/
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#requestBodyObject
    class RequestBodyObj < Hash
      include Helpers

      attr_accessor :processed, :media_types

      def initialize(required, desc)
        self.media_types = [ ]
        self.processed   = { required: required['req'].present?, description: desc }
      end

      def absorb(media_type, hash)
        media_types << MediaTypeObj.new(media_type, **hash)
        self
      end

      def process
        content = media_types.map(&:process).reduce({ }, &fusion)
        processed[:content] = content if content.present?
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
