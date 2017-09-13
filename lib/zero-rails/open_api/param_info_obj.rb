module ZeroRails
  module OpenApi
    module DSL
      class ParamInfoObj < Hash
        attr_accessor :processed, :schema
        def initialize(name, param_type, type, required)
          self.processed = {
              name: name,
              in: param_type,
              required: required,
              schema: { type: type }
          }
          self.schema = processed[:schema]
        end

        IS_PATTERNS = %w[email phone]
        def process
          processed[:description] = _description if _description.present?
          convent_range
          generate_enums_by_values;  schema[:enum] = _values if _values.present?
          recognize_pattern_in_name; schema[:format] = _is if _is.present?
          %i[length default regexp].each do |field|
            schema[field] = self.send("_#{field}") if self.send("_#{field}").present?
          end
        end
        def convent_range # to_array or minimum & maximum
          # Mainly for _values and _length
          MAPPING.keys.each do |key|
            setting = self.send(key)
            self[key] = setting.to_a if setting.present? && setting.is_a?(Range)
          end
        end
        def generate_enums_by_values
          values = self._values || self._value
          self._values = (values.is_a?(Array) ? values : [values]) if values.present?
        end
        def recognize_pattern_in_name
          # identify whether `is` patterns matched the name, if so, generate `is`.
          IS_PATTERNS.each do |pattern|
            self._is = pattern or break if "#{name}".match? /#{pattern}/
          end if _is.nil?
          self.delete :_is if _is.in?([:x, :we])
        end


        # Get the original values that was passed to param()
        MAPPING = {
            _values:      [:values],
            _length:      [:length, :lth],
            _value:       [:value],
            _is:          [:is, :is_a],
            _regexp:      [:regexp, :reg],
            _default:     [:default, :dft],
            _description: [:description, :desc, :d]
        }
        MAPPING.each do |method, aliases|
          define_method method do
            aliases.each do |alias_name|
              self[method] ||= self[alias_name]
            end if self[method].nil?
            self[method]
          end
          define_method "#{method}=" do |value| self[method] = value end
        end


        # Interfaces for directly taking value of processed parameter obj,
        #   through the key you focus on.
        def type;   schema[:type];   end
        def is;     schema[:format]; end
        def length; schema[:length]; end
        def values; schema[:enum];   end
        def regexp; schema[:regexp]; end

        [:name, :required].each do |dig_method|
          define_method dig_method do
            processed[dig_method]
          end
        end
      end
    end
  end
end