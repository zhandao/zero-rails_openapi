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
          SchemaObj.new(t[:type], t).process

          # For supporting combined schema in nested schema.
        elsif (t.keys & %i[ one_of any_of all_of not ]).present?
          CombinedSchema.new(t).process
        else
          obj_type(t)
        end
      end

      def obj_type(t)
        obj_type = { type: 'object', properties: { }, required: [ ] }

        t.each do |prop_name, prop_type|
          obj_type[:required] << prop_name.to_s.delete('!') if prop_name['!']
          obj_type[:properties][prop_name.to_s.delete('!').to_sym] = recg_schema_type(prop_type)
        end
        obj_type.keep_if &value_present
      end

      def array_type(t)
        {
            type: 'array',
            items: recg_schema_type(t.one? ? t[0] : { one_of: t })
        }
      end

      def str_range_to_a(val)
        val_class = val.first.class
        action = :"to_#{val_class.to_s.downcase[0]}"
        (val.first.to_s..val.last.to_s).to_a.map(&action)
      end

      def auto_generate_desc
        if @bang_enum.is_a?(Hash)
          @bang_enum.each_with_index do |(info, value), index|
            self._desc = _desc + "<br/>#{index + 1}/ #{info}: #{value}"
          end
        else
          @bang_enum.each_with_index { |value, index| self._desc = _desc + "<br/>#{index + 1}/ #{value}" }
        end
        _desc
      end
    end
  end
end
