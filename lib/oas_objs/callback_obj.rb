require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#callbackObject
    class CallbackObj < Hash
      include Helpers

      attr_accessor :event_name, :http_method, :callback_url, :block

      def initialize(event_name, http_method, callback_url, &block)
        self.event_name = event_name
        self.http_method = http_method
        self.callback_url = callback_url
        self.block = block
      end

      def process
        {
            self.event_name => {
                processed_url => {
                    self.http_method.downcase.to_sym => processed_block
                }
            }
        }
      end

      def processed_url
        self.callback_url.gsub(/{[^{}]*}/) do |exp|
          key_location, key_name = exp[1..-2].split
          connector = key_location == 'body' ? '#/' : '.'
          key_location = '$request.' + key_location
          ['{', key_location, connector, key_name, '}'].join
        end
      end

      def processed_block
        api = ApiInfo.new.merge! parameters: [ ], requestBody: '',  responses: { }
        api.instance_exec(&(self.block || ->{ }))
        api.process_objs
        api
      end
    end
  end
end


__END__

myEvent:
  '{$request.body#/callbackUrl}':
    post: # Method
      requestBody: # Contents of the callback message
        …
      responses: # Expected responses
        …

https://github.com/OAI/OpenAPI-Specification/blob/master/examples/v3.0/callback-example.yaml
