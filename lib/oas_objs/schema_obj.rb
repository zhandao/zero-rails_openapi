require 'oas_objs/helpers'
require 'open_api/config'
require 'oas_objs/ref_obj'
require 'oas_objs/example_obj'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#schemaObject
    class SchemaObj < Hash
      include Helpers

      attr_accessor :processed, :type

      def initialize(type, schema_hash)
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


      def process_for(param_name = nil, options = { desc_inside: false })
        return processed if @preprocessed

        processed.merge! processed_type
        reducx processed_enum_and_length,
               processed_range,
               processed_is_and_format(param_name),
               {
                   pattern:    _pattern&.inspect&.delete('/'),
                   default:    _default.nil? ? nil : '_default',
                   examples:   self[:examples].present? ? ExampleObj.new(self[:examples], self[:exp_by]).process : nil,
               },
               { as: _as, permit: _permit, not_permit: _npermit, req_if: _req_if, opt_if: _opt_if }
        then_merge!
        processed[:default] = _default unless _default.nil?

        reducx(processed_desc options).then_merge!
      end

      alias process process_for

      def preprocess_with_desc desc, param_name = nil
        self.__desc = desc
        process_for param_name
        @preprocessed = true
        __desc
      end

      def processed_desc(options)
        result = __desc ? self.__desc = process_desc : _desc
        options[:desc_inside] ? { description: result } : nil
      end

      # TODO: more info
      # TODO: desc configure
      def process_desc
        if processed[:enum].present?
          if @enum_info.present?
            @enum_info.each_with_index do |(info, value), index|
              __desc.concat "<br/>#{index + 1}/ #{info}: #{value}"
            end
          else
            processed[:enum].each_with_index do |value, index|
              __desc.concat "<br/>#{index + 1}/ #{value}"
            end
          end
        end
        __desc
      end

      def processed_type(type = self.type)
        t = type.class.in?([Hash, Array, Symbol]) ? type : "#{type}".downcase
        if t.is_a? Hash
          # For supporting writing:
          #   form 'desc', data: {
          #     id!: { type: Integer, enum: 0..5, desc: 'user id' }
          # }
          if t.key? :type
            SchemaObj.new(t[:type], t).process_for @prop_name, desc_inside: true
          else
            recursive_obj_type t
          end
        elsif t.is_a? Array
          recursive_array_type t
        elsif t.is_a? Symbol
          RefObj.new(:schema, t).process
        elsif t.in? %w[float double int32 int64] # to README: 这些值应该传 string 进来, symbol 只允许 $ref
          { type: t.match?('int') ? 'integer' : 'number', format: t}
        elsif t.in? %w[binary base64]
          { type: 'string', format: t}
        elsif t.eql? 'file'
          { type: 'string', format: Config.dft_file_format }
        elsif t.eql? 'datetime'
          { type: 'string', format: 'date-time' }
        else # other string
          { type: t }
        end
      end

      def recursive_obj_type(t) # DSL use { prop_name: prop_type } to represent object structure
        return processed_type(t) if !t.is_a?(Hash) || t.key?(:type)

        _schema = {
            type: 'object',
            properties: { },
            required: [ ]
        }
        t.each do |prop_name, prop_type|
          @prop_name = prop_name
          _schema[:required] << "#{prop_name}".delete('!') if prop_name['!']
          _schema[:properties]["#{prop_name}".delete('!').to_sym] = recursive_obj_type prop_type
        end
        _schema.keep_if &value_present
      end

      def recursive_array_type(t)
        if t.is_a? Array
          {
              type: 'array',
              # TODO: [[String], [Integer]] <= One Of? Object?(0=>[S], 1=>[I])
              items: recursive_array_type(t.first)
          }
        else
          processed_type t
        end
      end

      def processed_enum_and_length
        # Support this writing for auto generating desc from enum.
        #   enum: {
        #     'all_data': :all,
        #     'one_page': :one
        # }
        if _enum.is_a? Hash
          @enum_info = _enum
          self._enum = _enum.values
        end

        %i[_enum _length].each do |key|
          value = self.send(key)
          self[key] = value.to_a if value.present? && value.is_a?(Range)
        end

        # generate_enums_by_enum_array
        values = _enum || _value
        self._enum = Array(values) if truly_present?(values)

        # generate length range fields by _lth array
        lth = _length || [ ]
        max = lth.is_a?(Array) ? lth.first : ("#{lth}".match?('ge') ? "#{lth}".split('_').last.to_i : nil)
        min = lth.is_a?(Array) ? lth.last : ("#{lth}".match?('le') ? "#{lth}".split('_').last.to_i : nil)
        if processed[:type] == 'array'
          { minItems: max, maxItems: min }
        else
          { minLength: max, maxLength: min }
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

      def processed_is_and_format(name)
        return if name.nil?
        recognize_is_options_in name
        { }.tap do |it|
          # `format` that generated in process_type() may be overwrote here.
          it.merge!(format: _format || _is) if processed[:format].blank? || _format.present?
          it.merge! is: _is
        end
      end

      def recognize_is_options_in(name)
        # identify whether `is` patterns matched the name, if so, generate `is`.
        Config.is_options.each do |pattern|
          self._is = pattern or break if name.match? /#{pattern}/
        end if _is.nil?
      end


      { # SELF_MAPPING
          _enum:    %i[ enum     values  allowable_values ],
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
      }.each do |key, aliases|
        define_method key do
          aliases.each do |alias_name|
            break if self[key] == false
            self[key] ||= self[alias_name]
          end if self[key].nil?
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