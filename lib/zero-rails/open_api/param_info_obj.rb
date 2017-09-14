module ZeroRails
  module OpenApi
    module DSL
      class ParamInfoObj < Hash
        attr_accessor :processed, :schema
        def initialize(name, param_type, type, required)
          self.processed = {
              name: name,
              in: param_type,
              required: "#{required}".match?(/req/),
              # [Note] Here is no limit to type, even if the input isn't up to OAS,
              #          like: double, float, hash.
              #        My consideration is, OAS can't express some cases, for example:
              #          `total_price` should be double, is_a `price`, and match /^.*\..*$/
              #        However, user can decide how to write --
              #          `type: number, format: double`, or `type: double`
              schema: { type: type.class.in?([Hash, Array]) ? type : "#{type}".downcase }
          }
          self.schema = processed[:schema]
        end

        IS_PATTERNS = %w[email phone password uuid uri url time date]
        def process
          assign(_desc).to 'description'
          process_type
          lth = process_enum_and_length;   assign(lth).to_schema
          range = process_range;           assign(range).to_schema
          recognize_pattern_in_name

          %i[enum is pattern default].each do |field|
            assign(field).to_schema field
          end
        end
        def process_type
          t = schema[:type]
          if t.is_a? Hash
            schema.merge! process_obj_type t
          elsif t.is_a? Array
            schema.merge! recursive_array_type t
          elsif t.in? %w[float double int32 int64]
            schema[:type] = t.match?('int') ? 'integer' : 'number'
            schema[:format] = t
          elsif t.eql? 'object'
            schema[:additionalProperties] = { }
          end
        end
        def process_enum_and_length
          %i[_enum _length].each do |key|
            setting = self.send(key)
            self[key] = setting.to_a if setting.present? && setting.is_a?(Range)
          end

          # generate_enums_by_enum_array
          values = self._enum || self._value
          self._enum = (values.is_a?(Array) ? values : [values]) if not_empty?(values)

          # generate length range fields by _lth array
          lth = _length || [ ]
          if type == 'array'
            {
                minItems: lth.is_a?(Array) ? lth.first : nil,
                maxItems: lth.is_a?(Array) ? lth.last : nil
            }
          else
            {
                minLength: lth.is_a?(Array) ? lth.first : ("#{lth}".match?('ge') ? "#{lth}".split('_').last.to_i : nil),
                maxLength: lth.is_a?(Array) ? lth.last : ("#{lth}".match?('le') ? "#{lth}".split('_').last.to_i : nil)
            }
          end.delete_if { |_,v| v.blank? }
        end
        def process_range
          range = _range || { }
          {
              minimum: range[:gt] || range[:ge],
              exclusiveMinimum: range[:gt].present?,
              maximum: range[:lt] || range[:le],
              exclusiveMaximum: range[:lt].present?
          }.delete_if { |_,v| v.blank? }
        end
        def recognize_pattern_in_name
          # identify whether `is` patterns matched the name, if so, generate `is`.
          IS_PATTERNS.each do |pattern|
            self._is = pattern or break if "#{name}".match? /#{pattern}/
          end if _is.nil?
          self.delete :_is if _is.in?([:x, :we])
        end


        # Get the original values that was passed to param()
        { # SELF_MAPPING
            _enum:    %i[enum     values  allowable_values],
            _value:   %i[must_be  value   allowable_value ],
            _range:   %i[range    number_range            ],
            _length:  %i[length   lth                     ],
            _is:      %i[format   is      is_a            ],
            _pattern: %i[pattern  regexp  pr   reg        ],
            _default: %i[default  dft     default_value   ],
            _desc:    %i[desc     description             ],
        }.each do |key, aliases|
          define_method key do
            aliases.each do |alias_name|
              self[key] ||= self[alias_name]
            end if self[key].nil?
            self[key]
          end
          define_method "#{key}=" do |value| self[key] = value end
        end


        # Interfaces for directly taking value of processed parameter obj,
        #   through the key you focus on.
        { # INTERFACE_MAPPING
            name:     [:name],
            required: [:required],
            enum:     [:schema, :enum],
            pattern:  [:schema, :pattern],
            regexp:   [:schema, :pattern],
            type:     [:schema, :type],
            is:       [:schema, :format],
        }.each do |method, path|
          define_method method do path.inject(processed, &:[]) end # Get value from hash by key path
          define_method "#{method}=" do |value|
            (path[1].nil? ? processed : processed[path[0]])[path.last] = value
          end
        end
        alias_method :range, :_range
        alias_method :length, :_length


        # TODO: comment-block doc
        def not_empty?(obj); obj.eql?(false) || obj.present?; end
        def assign(value)
          @assign_value = value.is_a?(Symbol)? self.send("_#{value}") : value
          self
        end
        def to(who)
          if who.is_a?(Symbol)
            self.send("#{who}=", @assign_value)
          else
            processed[who.to_sym] = @assign_value
          end if not_empty?(@assign_value)
        end
        def to_schema(who = nil)
          if who.nil?
            schema.merge! @assign_value
          else
            schema[who.to_sym] = @assign_value
          end if not_empty?(@assign_value)
        end

        def process_obj_type(t)
          return { type: "#{t}".downcase } unless t.is_a? Hash

          _schema = {
              type: 'object',
              properties: { },
              required: [ ]
          }
          t.each do |k, v|
            _schema[:required] << "#{k}".delete('!') if "#{k}".match? '!'
            _schema[:properties]["#{k}".delete('!').to_sym] = process_obj_type v
          end
          _schema.delete_if { |_,v| v.blank? }
        end
        def recursive_array_type(t)
          if t.is_a? Array
            {
                type: 'array',
                items: recursive_array_type(t[0])
            }
          else
            if t.is_a? Hash
              process_obj_type t
            else
              s = { type: "#{t}".downcase }
              s.merge  additionalProperties: {} if "#{t}".eql? 'Object'
              s
            end
          end
        end
      end
    end
  end
end