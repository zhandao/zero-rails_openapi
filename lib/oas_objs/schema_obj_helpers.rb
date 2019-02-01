# frozen_string_literal: true

module OpenApi
  module DSL
    module SchemaObjHelpers
      def hash_type(t)
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
          obj_type(t)
        end
      end

      def obj_type(t)
        obj_type = { type: 'object', properties: { }, required: [ ] }

        t.each do |prop_name, prop_type|
          obj_type[:required] << prop_name.to_s.delete('!') if prop_name['!']
          obj_type[:properties][prop_name.to_s.delete('!').to_sym] = processed_type(prop_type)
        end
        obj_type.keep_if &value_present
      end

      def array_type(t)
        t = t.size == 1 ? t.first : { one_of: t }
        {
            type: 'array',
            items: processed_type(t)
        }
      end

      def process_range_enum_and_lth
        self[:_enum] = str_range_to_a(_enum) if _enum.is_a?(Range)
        self[:_length] = str_range_to_a(_length) if _length.is_a?(Range)

        values = _enum || _value
        self._enum = Array(values) if truly_present?(values)
      end

      def str_range_to_a(val)
        val_class = val.first.class
        action = :"to_#{val_class.to_s.downcase[0]}"
        (val.first.to_s..val.last.to_s).to_a.map(&action)
      end

      def process_enum_info
        # Support this writing for auto generating desc from enum.
        #   enum!: {
        #     'all_desc': :all,
        #     'one_desc': :one
        # }
        self._enum ||= (e = self[:enum!])
        return unless e.is_a? Hash
        @enum_info = e
        self._enum = e.values
      end

      # TODO: more info and desc configure
      def auto_generate_desc
        return __desc if _enum.blank?

        if @enum_info.present?
          @enum_info.each_with_index do |(info, value), index|
            self.__desc = __desc + "<br/>#{index + 1}/ #{info}: #{value}" # FIXME
          end
        else
          _enum.each_with_index do |value, index|
            self.__desc = __desc + "<br/>#{index + 1}/ #{value}"
          end
        end
        __desc
      end
    end
  end
end
