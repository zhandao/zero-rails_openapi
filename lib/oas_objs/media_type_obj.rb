# frozen_string_literal: true

require "oas_objs/schema_obj"
require "oas_objs/example_obj"

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#media-type-object
    class MediaTypeObj < Hash
      attr_accessor :media_type, :schema, :examples, :example

      def initialize(media_type, example: nil, examples: nil, exp_params: nil, **media_hash)
        schema_type     = media_hash.values_at(:type, :data).compact.first
        exp_params      = schema_type.keys if exp_params == :all
        self.examples   = ExampleObj.new(examples, exp_params, multiple: true) if examples.present?
        self.example    = ExampleObj.new(example) if example.present?
        self.media_type = media_type_mapping(media_type)
        self.schema     = SchemaObj.new(schema_type, media_hash.except(:type, :data))
      end

      def process
        return { } if media_type.nil?
        schema_processed = schema.process
        result = schema_processed.values.join.blank? ? { } : { schema: schema_processed }
        result[:example] = example.process unless example.nil?
        result[:examples] = examples.process unless examples.nil?
        { media_type => result }
      end

      # https://swagger.io/docs/specification/media-types/
      # https://en.wikipedia.org/wiki/Media_type
      # https://zh.wikipedia.org/wiki/%E4%BA%92%E8%81%94%E7%BD%91%E5%AA%92%E4%BD%93%E7%B1%BB%E5%9E%8B
      # https://www.iana.org/assignments/media-types/media-types.xhtml
      # :nocov:
      def media_type_mapping(media_type)
        return media_type if media_type.is_a? String
        case media_type
        when :app then   "application/*"
        when :json then  "application/json"
        when :xml then   "application/xml"
        when :xwww then  "application/x-www-form-urlencoded"
        when :pdf then   "application/pdf"
        when :zip then   "application/zip"
        when :gzip then  "application/gzip"
        when :doc then   "application/msword"
        when :docx then  "application/application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        when :xls then   "application/vnd.ms-excel"
        when :xlsx then  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        when :ppt then   "application/vnd.ms-powerpoint"
        when :pptx then  "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        when :form then  "multipart/form-data"; when :form_data then "multipart/form-data"
        when :text then  "text/*"
        when :plain then "text/plain then charset=utf-8"
        when :html then  "text/html"
        when :csv then   "text/csv"
        when :image then "image/*"
        when :png then   "image/png"
        when :jpeg then  "image/jpeg"
        when :gif then   "image/gif"
        when :audio then "audio/*"
        when :video then "video/*"
        else             nil
        end
      end
      # :nocov:
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
