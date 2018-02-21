require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#callbackObject
    class CallbackObj < Hash
      include Helpers

      attr_accessor :processed

      def initialize(http_method, callback_url, &block)
      end

      def process; processed end
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