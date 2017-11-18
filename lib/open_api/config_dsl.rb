module OpenApi
  module ConfigDSL
    def self.included(base)
      base.class_eval do
        module_function

        def api name, root_controller:
          @api = name
          register_docs[name] = { root_controller: root_controller }
        end

        def info version:, title:, **addition
          register_docs[@api].merge! version: version, title: title, **addition
        end

        def server url, desc: ''
          (register_docs[@api][:servers] ||= [ ]) << { url: url, description: desc }
        end

        def security requirement
          (register_docs[@api][:global_security] ||= [ ]) << requirement
        end

        alias_method :security_require, :security

        def security_scheme scheme_name, schema# = { }
          (register_docs[@api][:global_security_schemes] ||= { }).merge! scheme_name => schema
        end
      end
    end
  end
end
