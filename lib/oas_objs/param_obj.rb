require 'oas_objs/helpers'
require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    class ParamObj < Hash
      include Helpers

      attr_accessor :processed, :schema

      def initialize(name, param_type, type, required, schema)
        self.processed = {
            name: name,
            in: param_type,
            required: required.to_s.match?(/req/)
        }
        self.schema = schema.is_a?(CombinedSchema) ? schema : SchemaObj.new(type, schema)
        merge! schema
      end

      def process
        assign(desc).to_processed 'description'
        processed.tap { |it| it[:schema] = schema.process_for(processed[:name]) }
      end

      def desc
        if __desc.present?
          schema.preprocess_with_desc __desc, self[:name]
        else
          _desc
        end
      end


      # Getters and Setters of the original values that was passed to param()
      # This mapping allows user to select the aliases in DSL writing,
      #   without increasing the complexity of the implementation.
      { # SELF_MAPPING
          _range:  %i[ range   number_range ],
          _length: %i[ length  lth          ],
          _desc:   %i[ desc    description  ],
          __desc:  %i[ desc!   description! ],
      }.each do |key, aliases|
        define_method key do
          aliases.each { |alias_name| self[key] ||= self[alias_name] } if self[key].nil?
          self[key]
        end
      end
    end
  end
end


__END__

Parameter Object Examples
A header parameter with an array of 64 bit integer numbers:

{
  "name": "token",
  "in": "header",
  "description": "token to be passed as a header",
  "required": true,
  "schema": {
    "type": "array",
    "items": {
      "type": "integer",
      "format": "int64"
    }
  },
  "style": "simple"
}