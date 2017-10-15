module OpenApi
  module Config
    def self.included(base)
      base.extend ClassMethods
    end

    DEFAULT_CONFIG = {
        is_options: %w[email phone password uuid uri url time date],
        dft_file_format: 'binary'
    }.freeze

    module ClassMethods
      def config
        @config ||= ActiveSupport::InheritableOptions.new(DEFAULT_CONFIG)
      end

      def configure(&block)
        config.instance_eval &block
      end

      ### config options
      # register_docs = {
      #     doc_name: {
      #         file_output_path: '',
      #         root_controller: Base
      #         info: {}
      #     }}
      # is_options = %w[]
      # dft_file_format = 'base64'
      #
      # generate_jbuilder_file = true
      # jbuilder_template = <<-FILE
      #   jbuilder_template
      # FILE

      def apis
        @apis ||= @config.register_docs
      end
    end
  end
end
