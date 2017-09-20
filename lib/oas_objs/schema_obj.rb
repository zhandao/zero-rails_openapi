require 'oas_objs/helpers'
require 'open_api/config'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#schemaObject
    class SchemaObj < Hash
      include Helpers

      attr_accessor :processed, :type
      def initialize(type)
        self.processed = { }
        # [Note] Here is no limit to type, even if the input isn't up to OAS,
        #          like: double, float, hash.
        #        My consideration is, OAS can't express some cases like:
        #          `total_price` should be double, is_a `price`, and match /^.*\..*$/
        #        However, user can decide how to write --
        #          `type: number, format: double`, or `type: double`
        self.type = type
      end


      def process_for(param_name = nil)
        processed.merge! processed_type
        all(processed_enum_and_length,
            processed_range,
            processed_is_and_format(param_name),
            { pattern: _pattern, default: _default }
        ).for_merge
      end
      alias_method :process, :process_for

      def processed_type(type = self.type)
        t = type.class.in?([Hash, Array, Symbol]) ? type : "#{type}".downcase
        if t.is_a? Hash
          recursive_obj_type t
        elsif t.is_a? Array
          recursive_array_type t
        elsif t.is_a? Symbol
          { '$ref': "#/components/schemas/#{t}" }
        elsif t.in? %w[float double int32 int64]
          { type: t.match?('int') ? 'integer' : 'number', format: t}
        elsif t.eql? 'object'
          { type: 'object', additionalProperties: { } } # TODO
        else # other string
          { type: t }
        end
      end
      def recursive_obj_type(t) # DSL use { k:v } to represent object structure
        return processed_type(t) unless t.is_a? Hash

        _schema = {
            type: 'object',
            properties: { },
            required: [ ]
        }
        t.each do |k, v|
          _schema[:required] << "#{k}".delete('!') if "#{k}".match? '!'
          _schema[:properties]["#{k}".delete('!').to_sym] = recursive_obj_type v
        end
        _schema.keep_if &value_present
      end
      def recursive_array_type(t)
        if t.is_a? Array
          {
              type: 'array',
              items: recursive_array_type(t[0])
          }
        else
          processed_type t
        end
      end

      def processed_enum_and_length
        %i[_enum _length].each do |key|
          value = self.send(key)
          self[key] = value.to_a if value.present? && value.is_a?(Range)
        end

        # generate_enums_by_enum_array
        values = _enum || _value
        self._enum = (values.is_a?(Array) ? values : [values]) if truly_present?(values)

        # generate length range fields by _lth array
        lth = _length || [ ]
        if self[:type] == 'array'
          {
              minItems: lth.is_a?(Array) ? lth.first : nil,
              maxItems: lth.is_a?(Array) ? lth.last : nil
          }
        else
          {
              minLength: lth.is_a?(Array) ? lth.first : ("#{lth}".match?('ge') ? "#{lth}".split('_').last.to_i : nil),
              maxLength: lth.is_a?(Array) ? lth.last : ("#{lth}".match?('le') ? "#{lth}".split('_').last.to_i : nil)
          }
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
        OpenApi.config.is_options.each do |pattern|
          self._is = pattern or break if "#{name}".match? /#{pattern}/
        end if _is.nil?
        self.delete :_is if _is.in?([:x, :we])
      end


      { # SELF_MAPPING
        _enum:    %i[enum     values  allowable_values],
        _value:   %i[must_be  value   allowable_value ],
        _range:   %i[range    number_range            ],
        _length:  %i[length   lth                     ],
        _is:      %i[is_a     is                      ], # NOT OAS Spec, just a addition
        _format:  %i[format   fmt                     ],
        _pattern: %i[pattern  regexp  pr   reg        ],
        _default: %i[default  dft     default_value   ],
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