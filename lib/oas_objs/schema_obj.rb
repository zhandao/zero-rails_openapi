require 'oas_objs/helpers'
require 'open_api/config'
require 'oas_objs/ref_obj'
require 'oas_objs/example_obj'
require 'oas_objs/schema_obj_helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#schemaObject
    class SchemaObj < Hash
      include SchemaObjHelpers
      include Helpers

      attr_accessor :processed, :type, :preprocessed

      def initialize(type, schema_hash)
        self.preprocessed = false
        self.processed = { }
        # [Note] Here is no limit to type, even if the input isn't up to OAS,
        #          like: double, float, hash.
        #        My consideration is, OAS can't express some cases like:
        #          `total_price` should be double, is_a `price`, and match /^.*\..*$/
        #        However, user can decide how to write --
        #          `type: number, format: double`, or `type: double`
        self.type = type
        merge! schema_hash
      end

      def process(options = { inside_desc: false })
        return processed if preprocessed

        processed.merge!(processed_type)
        reducx(
            processed_enum_and_length,
            processed_range,
            processed_is_and_format,
            {
                pattern:    _pattern.is_a?(String)? _pattern : _pattern&.inspect&.delete('/'),
                default:    _default,
                examples:   self[:examples].present? ? ExampleObj.new(self[:examples], self[:exp_by]).process : nil
            },
            { as: _as, permit: _permit, not_permit: _npermit, req_if: _req_if, opt_if: _opt_if, blankable: _blank },
        ).then_merge!
        reducx(processed_desc(options)).then_merge! # TODO
      end

      def preprocess_with_desc desc
        self.__desc = desc
        process
        self.preprocessed = true
        __desc
      end

      def processed_desc(options)
        result = __desc ? auto_generate_desc : _desc
        options[:inside_desc] ? { description: result } : nil
      end

      def processed_type(type = self.type)
        t = type.class.in?([Hash, Array, Symbol]) ? type : type.to_s.downcase
        if t.is_a? Hash
          processed_hash_type(t)
        elsif t.is_a? Array
          processed_array_type(t)
        elsif t.is_a? Symbol
          RefObj.new(:schema, t).process
        elsif t.in? %w[ float double int32 int64 ]
          { type: t.match?('int') ? 'integer' : 'number', format: t }
        elsif t.in? %w[ binary base64 ]
          { type: 'string', format: t }
        elsif t == 'file'
          { type: 'string', format: Config.file_format }
        elsif t == 'datetime'
          { type: 'string', format: 'date-time' }
        else # other string
          { type: t }
        end
      end

      def processed_hash_type(t)
        # For supporting this:
        #   form 'desc', type: {
        #     id!: { type: Integer, enum: 0..5, desc: 'user id' }
        # }, should have description within schema
        if t.key?(:type)
          SchemaObj.new(t[:type], t).process(inside_desc: true)

        # For supporting combined schema in nested schema.
        elsif (t.keys & %i[ one_of any_of all_of not ]).present?
          CombinedSchema.new(t).process(inside_desc: true)
        else
          processed_obj_type(t)
        end
      end

      def processed_enum_and_length
        process_enum_info
        process_range_enum_and_lth

        # generate length range fields by _lth array
        if (lth = _length || [ ]).is_a?(Array)
          min, max = [lth.first&.to_i, lth.last&.to_i]
        elsif lth['ge']
          max = lth.to_s.split('_').last.to_i
        elsif lth['le']
          min = lth.to_s.split('_').last.to_i
        end

        if processed[:type] == 'array'
          { minItems: min, maxItems: max }
        else
          { minLength: min, maxLength: max }
        end.merge!(enum: _enum).keep_if &value_present
      end

      def processed_range
        range = _range || { }
        {
            minimum: range[:gt] || range[:ge],
            exclusiveMinimum: range[:gt].present? ? true : nil,
            maximum: range[:lt] || range[:le],
            exclusiveMaximum: range[:lt].present? ? true : nil
        }.keep_if &value_present
      end

      def processed_is_and_format
        result = { is: _is }
        # `format` that generated in process_type() may be overwrote here.
        result[:format] = _format || _is if processed[:format].blank? || _format.present?
        result
      end


      { # SELF_MAPPING
          _enum:    %i[ enum in  values  allowable_values ],
          _value:   %i[ must_be  value   allowable_value  ],
          _range:   %i[ range    number_range             ],
          _length:  %i[ length   lth     size             ],
          _is:      %i[ is_a     is                       ], # NOT OAS Spec, see documentation/parameter.md
          _format:  %i[ format   fmt                      ],
          _pattern: %i[ pattern  regexp  pt   reg         ],
          _default: %i[ default  dft     default_value    ],
          _desc:    %i[ desc     description  d           ],
          __desc:   %i[ desc!    description! d!          ],
          _as:      %i[ as   to  for     map  mapping     ], # NOT OAS Spec, it's for zero-params_processor
          _permit:  %i[ permit   pmt                      ], # NOT OAS Spec, it's for zero-params_processor
          _npermit: %i[ npmt     not_permit   unpermit    ], # NOT OAS Spec, it's for zero-params_processor
          _req_if:  %i[ req_if   req_when                 ], # NOT OAS Spec, it's for zero-params_processor
          _opt_if:  %i[ opt_if   opt_when                 ], # NOT OAS Spec, it's for zero-params_processor
          _blank:   %i[ blank    blankable                ], # NOT OAS Spec, it's for zero-params_processor
      }.each do |key, aliases|
        define_method key do
          return self[key] unless self[key].nil?
          
          aliases.each do |alias_name|
            break if self[key] == false
            self[key] ||= self[alias_name]
          end
          self[key]
        end
        define_method "#{key}=" do |value| self[key] = value end
      end
    end
  end
end


__END__

Schema Object Examples

Primitive Sample

{
  "type": "string",
  "format": "email",
  "examples": {
    "exp1": {
      "value": 'val'
    }
  }
}

Simple Model

{
  "type": "object",
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string"
    },
    "address": {
      "$ref": "#/components/schemas/Address"
    },
    "age": {
      "type": "integer",
      "format": "int32",
      "minimum": 0
    }
  }
}