# frozen_string_literal: true

require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#header-object
    class HeaderObj < Hash
      include Helpers

      attr_accessor :processed, :schema

      def initialize(desc = '', schema)
        self.schema = SchemaObj.new(schema)
        self.processed = { description: desc }
      end

      def process
        schema.process
        processed.merge!(schema: schema)
      end
    end
  end
end


__END__

Header Object Example

{
  "description": "The number of allowed requests in the current period",
  "schema": {
    "type": "integer"
  }
}
