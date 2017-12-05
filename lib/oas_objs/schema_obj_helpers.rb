module OpenApi
  module DSL
    module SchemaObjHelpers
      # TODO: more info
      # TODO: desc configure
      def auto_generate_desc
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

      def recursive_obj_type(t) # ZRO use { prop_name: prop_type } to represent object structure
        return processed_type(t) if !t.is_a?(Hash) || (t.keys & %i[ type one_of any_of all_of not ]).present?

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
        _schema.keep_if(&value_present)
      end

      def recursive_array_type(t)
        return processed_type(t) unless t.is_a? Array

        {
            type: 'array',
            # TODO: [[String], [Integer]] <= One Of? Object?(0=>[S], 1=>[I])
            items: recursive_array_type(t.first)
        }
      end

      def process_enum_lth_range
        self[:_enum] = _enum.to_a if _enum.present? && _enum.is_a?(Range)
        self[:_length] = _length.to_a if _length.present? && _length.is_a?(Range)

        # generate_enums_by_enum_array
        values = _enum || _value
        self._enum = Array(values) if truly_present?(values)
      end

      def process_enum_info
        # Support this writing for auto generating desc from enum.
        #   enum: {
        #     'all_data': :all,
        #     'one_page': :one
        # }
        if _enum.is_a? Hash
          @enum_info = _enum
          self._enum = _enum.values
        end
      end
    end
  end
end
