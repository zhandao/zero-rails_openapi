require 'oas_objs/helpers'
require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#responseObject
    class ResponseObj < Hash

      attr_accessor :processed, :code, :media_type, :schema
      def initialize(code, desc, media_type, schema_hash)
        self.code       = "#{code}"
        self.media_type = media_type
        self.schema     = SchemaObj.new(schema_hash[:type]).merge! schema_hash
        self.processed  = { description: desc }
      end

      def process
        schema_processed = self.schema.process
        schema = schema_processed.values.join.blank? ? { } : { schema: schema_processed }
        content = media_type_mapping.nil? ? { } : { media_type_mapping =>  schema }
        processed[:content] = content if content.present?
        { code => processed }
      end

      def media_type_mapping
        return media_type if media_type.is_a? String

        case media_type
          when :json; 'application/json'
          else; nil
        end
      end
    end
  end
end
