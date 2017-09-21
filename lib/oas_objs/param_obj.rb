require 'oas_objs/helpers'
require 'oas_objs/schema_obj'

module OpenApi
  module DSL
    class ParamObj < Hash
      include Helpers

      attr_accessor :processed, :schema
      def initialize(name, param_type, type, required, schema_hash)
        self.processed = {
            name: name,
            in: param_type,
            required: "#{required}".match?(/req/),
        }
        self.schema = SchemaObj.new(type, schema_hash)
        self.merge! schema_hash
      end

      def process
        assign(_desc).to_processed 'description'
        processed.tap { |it| it[:schema] = schema.process_for name }
      end


      # Getters and Setters of the original values that was passed to param()
      # This mapping allows user to select the aliases in DSL writing,
      #   without increasing the complexity of the implementation.
      { # SELF_MAPPING
          _range:  %i[range   number_range],
          _length: %i[length  lth         ],
          _desc:   %i[desc    description ],
      }.each do |key, aliases|
        define_method key do
          aliases.each { |alias_name| self[key] ||= self[alias_name] } if self[key].nil?
          self[key]
        end
      end


      # Interfaces for directly taking the info what you focus on,
      #   The next step you may want to verify the parameters based on these infos.
      #   The implementation of the parameters validator, see:
      #     TODO
      alias_method :range, :_range
      alias_method :length, :_length
      { # INTERFACE_MAPPING
          name:     %i[name          ],
          required: %i[required      ],
          in:       %i[in            ],
          enum:     %i[schema enum   ],
          pattern:  %i[schema pattern],
          regexp:   %i[schema pattern],
          type:     %i[schema type   ],
          is:       %i[schema format ],
      }.each do |method, path|
        define_method method do path.inject(processed, &:[]) end # Get value from hash by key path
      end
      alias_method :required?, :required
      # is_email? ..
      # Config.DEFAULT_CONFIG[:patterns].each do |pattern|
      #   define_method "is_#{pattern}?" do self.is.eql? pattern end
      # end
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