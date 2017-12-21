module OpenApi
  module DSL
    module SchemaObjHelpers
      # TODO: more info and desc configure
      def auto_generate_desc
        return __desc if processed[:enum].blank?

        if @enum_info.present?
          @enum_info.each_with_index do |(info, value), index|
            __desc.concat "<br/>#{index + 1}/ #{info}: #{value}"
          end
        else
          processed[:enum].each_with_index do |value, index|
            __desc.concat "<br/>#{index + 1}/ #{value}"
          end
        end
        __desc
      end

      def processed_obj_type(t)
        obj_type = { type: 'object', properties: { }, required: [ ] }

        t.each do |prop_name, prop_type|
          obj_type[:required] << prop_name.to_s.delete('!') if prop_name['!']
          obj_type[:properties][prop_name.to_s.delete('!').to_sym] = processed_type(prop_type)
        end
        obj_type.keep_if &value_present
      end

      def processed_array_type(t)
        t = t.size == 1 ? t.first : { one_of: t }
        {
            type: 'array',
            items: processed_type(t)
        }
      end

      def process_range_enum_and_lth
        self[:_enum] = str_range_2a(_enum) if _enum.present? && _enum.is_a?(Range)
        self[:_length] = str_range_2a(_length) if _length.present? && _length.is_a?(Range)

        values = _enum || _value
        self._enum = Array(values) if truly_present?(values)
      end

      def str_range_2a(val)
        val_class = val.first.class
        action = "to_#{val_class.to_s.downcase[0]}".to_sym
        (val.first.to_s..val.last.to_s).to_a.map(&action)
      end

      def process_enum_info
        # Support this writing for auto generating desc from enum.
        #   enum!: {
        #     'all_desc': :all,
        #     'one_desc': :one
        # }
        self._enum ||= self[:enum!]
        return unless self[:enum!].is_a? Hash
        @enum_info = self[:enum!]
        self._enum = self[:enum!].values
      end
    end
  end
end
