module ZeroRails
  module OpenApi
    module Config
      def self.included(base)
        base.extend ClassMethods
      end

      DEFAULT_CONFIG = {

      }

      module ClassMethods
        def config
          @config ||= ActiveSupport::InheritableOptions.new(DEFAULT_CONFIG)
        end

        def configure(&block)
          config.instance_eval &block
        end

        ### config options
        # register_apis = {
        #     version: {
        #         :file_output_path, :root_controller
        #         info: {}
        #     }}
        # patterns = %w[]

        def apis
          @apis ||= @config.register_apis
        end
      end
    end
  end
end
