module OpenApi
  module Helpers

    # TODO: comment-block doc
    def truly_present?(obj)
      obj == false || obj.present?
    end

    def value_present
      Proc.new { |_, v| truly_present? v }
    end

    def assign(value)
      @assign = value.is_a?(Symbol)? self.send("_#{value}") : value
      self
    end

    def all(*values)
      @assign = values.compact.reduce({ }, :merge).keep_if &value_present
      self
    end

    def to_processed(who)
      if who.is_a?(Symbol)
        self.send("#{who}=", @assign)
      else
        processed[who.to_sym] = @assign
      end if truly_present?(@assign)

      processed
    end

    def to(who)
      self[who.to_sym] = @assign if truly_present?(@assign)
    end

    def for_merge # to_processed
      processed.tap { |it| it.merge! @assign if truly_present?(@assign) }
    end
  end
end
