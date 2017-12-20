module OpenApi
  module DSL
    module SchemaObjHelpers
      # TODO: more info and desc configure
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

      def recursive_obj_type(t)
        obj_type = { type: 'object', properties: { }, required: [ ] }
        t.each do |prop_name, prop_type|
          obj_type[:required] << prop_name.to_s.delete('!') if prop_name['!']
          obj_type[:properties][prop_name.to_s.delete('!').to_sym] = processed_type(prop_type)
        end
        obj_type.keep_if(&value_present)
      end

      def recursive_array_type(t)
        t = t.size == 1 ? t.first : { one_of: t }
        {
            type: 'array',
            items: processed_type(t)
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
