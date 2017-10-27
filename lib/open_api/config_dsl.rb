module OpenApi
  module ConfigDSL
    def self.included(base)
      base.class_eval do
        module_function

        def info
          1
        end
      end
    end
  end
end
