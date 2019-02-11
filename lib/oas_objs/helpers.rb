# frozen_string_literal: true

module OpenApi
  module Helpers
    def fusion
      proc { |a, b| a.deep_merge!(b) { |common_key, va, vb| common_key == :required ? va + vb : vb } }
    end

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

    # reducx.then_merge! => for Hash
    def reducx(*values)
      @assign = values.compact.reduce({ }, :merge!).keep_if &value_present
      self
    end

    def to_processed(who)
      return processed unless truly_present?(@assign)
      processed[who.to_sym] = @assign
      processed
    end

    def then_merge! # to_processed
      processed.tap { |it| it.merge! @assign if truly_present?(@assign) }
      # processed
    end
  end
end
