module OpenApi
  module Helpers
    def truly_present?(obj)
      obj == false || obj.present?
    end

    def value_present
      proc { |_, v| truly_present? v }
    end

    # assign.to
    def assign(value)
      @assign = value.is_a?(Symbol) ? send("_#{value}") : value
      self
    end

    # reduceee.then_merge! => for Hash
    def reducx(*values)
      @assign = values.compact.reduce({ }, :merge).keep_if &value_present
      self
    end

    def to_processed(who)
      return processed unless truly_present?(@assign)

      if who.is_a?(Symbol)
        send("#{who}=", @assign)
      else
        processed[who.to_sym] = @assign
      end

      processed
    end

    def to(who)
      self[who.to_sym] = @assign if truly_present?(@assign)
    end

    def then_merge! # to_processed
      processed.tap { |it| it.merge! @assign if truly_present?(@assign) }
    end
  end
end
