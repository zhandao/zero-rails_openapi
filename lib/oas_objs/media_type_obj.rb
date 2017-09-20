require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#media-type-object
    class MediaTypeObj < Hash
      attr_accessor :media_type, :schema
      def initialize(media_type, schema_hash)
        self.media_type = media_type
        self.schema     = SchemaObj.new(schema_hash[:type]).merge! schema_hash
      end

      def process
        schema_processed = self.schema.process
        schema = schema_processed.values.join.blank? ? { } : { schema: schema_processed }
        media_type_mapping.nil? ? { } : { media_type_mapping =>  schema }
      end

      # https://swagger.io/docs/specification/media-types/
      def media_type_mapping
        return media_type if media_type.is_a? String
        case media_type
          when :json;  'application/json'
          when :xml;   'application/xml'
          when :xwww;  'application/x-www-form-urlencoded'
          when :form;  'multipart/form-data'
          when :plain; 'text/plain; charset=utf-8'
          when :html;  'text/html'
          when :pdf;   'application/pdf'
          when :png;   'image/png'
          else; nil
        end
      end
    end
  end
end
