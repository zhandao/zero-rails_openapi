# frozen_string_literal: true

module OpenApi
  module Tip
    extend self

    def no_config; puts '    OpenApi'.red + ' No documents have been configured!' end
    def loaded;    puts '    OpenApi'.green + ' loaded' end

    def generated(name)
      puts '    OpenApi'.green + " `#{name}.json` has been generated."
    end

    def schema_no_type(component_key)
      puts '    OpenApi'.red + " Syntax Error: component schema `#{component_key}` has no type!"
    end

    def param_no_type(name)
      puts '    OpenApi'.red + " Syntax Error: param `#{name}` has no schema type!"
    end

    def no_route(action_path)
      puts '    OpenApi'.red + " Route mapping failed: #{action_path}"
    end
  end
end
