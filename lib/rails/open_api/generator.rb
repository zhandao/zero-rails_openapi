module Rails
  module OpenApi
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def generate_doc

      end
    end
  end
end
