module ZeroRails
  module OpenApi
    module DSL
      class ParamInfoObj < Hash
        attr_accessor :processed
        def initialize(name, param_type, type, required)
          self.processed = {
              name: name,
              in: param_type,
              required: required,
              schema: {
                  type: type
              }
          }
        end

        IS_PATTERNS = %w[email phone]
        def process
          processed[:description] = _description if _description.present?
          convent_range_to_array
          recognize_pattern_in_name; processed[:schema][:format] = _is if _is.present?
        end
        def convent_range_to_array
          MAPPING.keys.each do |key|
            setting = self.send(key)
            self[key] = setting.to_a if setting.present? && setting.is_a?(Range)
          end
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
            _doc_default: [:doc_default, :dft],
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

        def values

        end


        # Interfaces for directly taking value of processed parameter obj,
        #   through the key you focus on.
        def type

        end

        def is
          processed[:schema][:format]
        end

        [:name, :required].each do |dig_method|
          define_method dig_method do
            processed[dig_method]
          end
        end
      end
    end
  end
end