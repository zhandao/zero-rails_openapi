require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#media-type-object
    class MediaTypeObj < Hash
      attr_accessor :media_type, :schema
      def initialize(media_type, schema_hash)
        self.media_type = media_type_mapping media_type
        self.schema     = SchemaObj.new(schema_hash[:type], schema_hash)
      end

      def process
        schema_processed = self.schema.process
        schema = schema_processed.values.join.blank? ? { } : { schema: schema_processed }
        media_type.nil? ? { } : { media_type =>  schema }
      end

      # https://swagger.io/docs/specification/media-types/
      # https://en.wikipedia.org/wiki/Media_type
      # https://zh.wikipedia.org/wiki/%E4%BA%92%E8%81%94%E7%BD%91%E5%AA%92%E4%BD%93%E7%B1%BB%E5%9E%8B
      # https://www.iana.org/assignments/media-types/media-types.xhtml
      def media_type_mapping(media_type)
        return media_type if media_type.is_a? String
        case media_type
          when :app;   'application/*'
          when :json;  'application/json'
          when :xml;   'application/xml'
          when :xwww;  'application/x-www-form-urlencoded'
          when :pdf;   'application/pdf'
          when :zip;   'application/zip'
          when :gzip;  'application/gzip'
          when :doc;   'application/msword'
          when :docx;  'application/application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          when :xls;   'application/vnd.ms-excel'
          when :xlsx;  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          when :ppt;   'application/vnd.ms-powerpoint'
          when :pptx;  'application/vnd.openxmlformats-officedocument.presentationml.presentation'
          # when :pdf;   'application/pdf'
          when :form;  'multipart/form-data'; when :form_data; 'multipart/form-data'
          when :text;  'text/*'
          when :plain; 'text/plain; charset=utf-8'
          when :html;  'text/html'
          when :csv;   'text/csv'
          when :image; 'image/*'
          when :png;   'image/png'
          when :jpeg;  'image/jpeg'
          when :gif;   'image/gif'
          when :audio; 'audio/*'
          when :video; 'video/*'
          else;        nil
        end
      end
    end
  end
end


__END__

Media Type Examples

{
  "application/json": {
    "schema": {
         "$ref": "#/components/schemas/Pet"
    },
    "examples": {
      "cat" : {
        "summary": "An example of a cat",
        "value":
          {
            "name": "Fluffy",
            "petType": "Cat",
            "color": "White",
            "gender": "male",
            "breed": "Persian"
          }
      },
      "frog": {
          "$ref": "#/components/examples/frog-example"
        }
      }
    }
  }
}