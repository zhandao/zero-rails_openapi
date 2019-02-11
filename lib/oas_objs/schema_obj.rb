# frozen_string_literal: true

require 'oas_objs/helpers'
require 'oas_objs/ref_obj'
require 'oas_objs/example_obj'
require 'oas_objs/schema_obj_helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#schemaObject
    class SchemaObj < Hash
      include SchemaObjHelpers
      include Helpers

      attr_accessor :processed, :type

      def initialize(type = nil, schema)
        merge!(schema)
        self.processed = { type: nil, format: nil, **schema.except(:type, :range, :enum!, *SELF_MAPPING.values.flatten) }
        self.type = type || self[:type]
      end

      def process(options = { inside_desc: false })
        processed.merge!(processed_type)
        reducx(additional_properties, enum_and_length, range, format, other, desc(options)).then_merge!
        processed.keep_if &value_present
      end

      def desc(inside_desc:)
        result = @bang_enum.present? ? auto_generate_desc : _desc
        # return unless inside_desc
        { description: result }
      end

      def processed_type(t = self.type)
        t = t.class.in?([Hash, Array, Symbol]) ? t : t.to_s.downcase
        if t.is_a? Hash
          hash_type(t)
        elsif t.is_a? Array
          array_type(t)
        elsif t.is_a? Symbol
          RefObj.new(:schema, t).process
        elsif t.in? %w[ float double int32 int64 ]
          { type: t['int'] ? 'integer' : 'number', format: t }
        elsif t.in? %w[ binary base64 uri ]
          { type: 'string', format: t }
        elsif t == 'file' # TODO
          { type: 'string', format: Config.file_format }
        elsif t == 'datetime'
          { type: 'string', format: 'date-time' }
        elsif t[/\{=>.*\}/]
          self[:values_type] = t[3..-2]
          { type: 'object' }
        else # other string
          { type: t }
        end
      end

      def additional_properties
        return { } if processed[:type] != 'object' || _addProp.nil?
        {
            additionalProperties: SchemaObj.new(_addProp, { }).process(inside_desc: true)
        }
      end

      def enum_and_length
        process_enum_info
        process_range_enum_and_lth

        # generate length range fields by _lth array
        if (lth = _length || '').is_a?(Array)
          min, max = [lth.first&.to_i, lth.last&.to_i]
        elsif lth['ge']
          min = lth.to_s.split('_').last.to_i
        elsif lth['le']
          max = lth.to_s.split('_').last.to_i
        end

        if processed[:type] == 'array'
          { minItems: min, maxItems: max }
        else
          { minLength: min, maxLength: max }
        end.merge!(enum: _enum).keep_if &value_present
      end

      def range
        range = self[:range] || { }
        {
                     minimum: range[:gt] || range[:ge],
            exclusiveMinimum: range[:gt].present? ? true : nil,
                     maximum: range[:lt] || range[:le],
            exclusiveMaximum: range[:lt].present? ? true : nil
        }
      end

      def format
        # `format` that generated in process_type() may be overwrote here.
        processed[:format].blank? ? { format: self[:format] || self[:is_a] } : { }
      end

      def other
        {
            pattern:  _pattern.is_a?(String) ? _pattern : _pattern&.inspect&.delete('/'),
            example:  ExampleObj.new(self[:example]).process,
            examples: ExampleObj.new(self[:examples], self[:exp_by], multiple: true).process
        }
      end


      SELF_MAPPING = {
          _enum:    %i[ enum in  values  allowable_values ],
          _length:  %i[ length   lth     size             ],
          _pattern: %i[ pattern  regexp                   ],
          _desc:    %i[ desc     description  d           ],
          _addProp: %i[ additional_properties add_prop values_type ],
      }.each do |key, aliases|
        define_method key do
          return self[key] unless self[key].nil?
          aliases.each { |alias_name| self[key] = self[alias_name] if self[key].nil? }
          self[key]
        end
        define_method("#{key}=") { |value| self[key] = value }
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