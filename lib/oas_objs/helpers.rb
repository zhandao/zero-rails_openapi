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

    def reducing(*values)
      values.compact.reduce(processed, :merge!).keep_if &value_present
    end
  end
end
