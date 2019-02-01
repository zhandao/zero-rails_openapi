# frozen_string_literal: true

require 'oas_objs/helpers'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#referenceObject
    class RefObj < Hash
      include Helpers

      attr_accessor :processed
      def initialize(ref_to, component_key)
        self.processed = {
            '$ref': "#/components/#{ref_to.to_s.pluralize}/#{component_key}"
        }
      end

      def process; processed end
      def name; nil end
    end
  end
end


__END__

Reference Object Example

{
	"$ref": "#/components/schemas/Pet"
}
