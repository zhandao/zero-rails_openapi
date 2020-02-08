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
        self.merge!(schema)
        self.processed = { type: nil, format: nil, **schema.except(:type, :range, :enum!, *SELF_MAPPING.values.flatten) }
        self.type = type || self[:type]
      end

      def process
        processed.merge!(recg_schema_type)
        reducing(additional_properties, enum, length, range, format, other, desc)
      end

      def desc
        return unless (result = @bang_enum.present? ? auto_generate_desc : _desc)
        { description: result }
      end

      def recg_schema_type(t = self.type)
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
        elsif t[/{=>.*}/]
          self[:values_type] = t[3..-2]
          { type: 'object' }
        else # other string
          { type: t }
        end
      end

      def additional_properties
        return if processed[:type] != 'object'
        default = Config.additional_properties_default_value_of_type_object
        return { additionalProperties: default } if _addProp.nil? && !default.nil?

        value = _addProp.in?([true, false]) ? _addProp : SchemaObj.new(_addProp, { }).process
        { additionalProperties: value }
      end

      def enum
        self._enum = str_range_to_a(_enum) if _enum.is_a?(Range)
        # Support this writing for auto generating desc from enum.
        #   enum!: {
        #     'all_desc': :all,
        #     'one_desc': :one
        # }
        if (@bang_enum = self[:enum!])
          self._enum ||= @bang_enum.is_a?(Hash) ? @bang_enum.values : @bang_enum
        end
        { enum: _enum }
      end

      def length
        return unless _length
        self._length = str_range_to_a(_length) if _length.is_a?(Range)

        if _length.is_a?(Array)
          min, max = [ _length.first&.to_i, _length.last&.to_i ]
        else
          min, max = _length[/ge_(.*)/, 1]&.to_i, _length[/le_(.*)/, 1]&.to_i
        end

        processed[:type] == 'array' ? { minItems: min, maxItems: max } : { minLength: min, maxLength: max }
      end

      def range
        (range = self[:range]) or return
        {
                     minimum: range[:gt] || range[:ge],
            exclusiveMinimum: range[:gt].present? || nil,
                     maximum: range[:lt] || range[:le],
            exclusiveMaximum: range[:lt].present? || nil
        }
      end

      def format
        { format: self[:format] || self[:is_a] } unless processed[:format]
      end

      def other
        {
            pattern:  _pattern.is_a?(String) ? _pattern : _pattern&.inspect&.delete('/'),
            example:  ExampleObj.new(self[:example]).process,
            examples: ExampleObj.new(self[:examples], self[:exp_params], multiple: true).process
        }
      end


      SELF_MAPPING = {
          _enum:    %i[ enum in  values  allowable_values ],
          _length:  %i[ length   lth     size             ],
          _pattern: %i[ pattern  regexp                   ],
          _desc:    %i[ desc     description  d           ],
          _addProp: %i[ additional_properties add_prop values_type ],
      }.each do |key, aliases|
        define_method(key)       { self[key] ||= self.values_at(*aliases).compact.first }
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