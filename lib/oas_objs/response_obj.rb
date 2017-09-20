require 'oas_objs/media_type_obj'
require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#responseObject
    class ResponseObj < Hash
      include Helpers

      attr_accessor :processed, :code, :media_type
      def initialize(code, desc, media_type, schema_hash)
        self.code       = "#{code}"
        self.media_type = MediaTypeObj.new(media_type, schema_hash)
        self.processed  = { description: desc }
      end

      def process
        assign(media_type.process).to_processed 'content'
        { code => processed }
      end
    end
  end
end
