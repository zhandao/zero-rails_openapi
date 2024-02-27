# frozen_string_literal: true

require 'oas_objs/helpers'
require 'oas_objs/ref_obj'

module OpenApi
  module DSL
    # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#exampleObject
    class ExampleObj < Hash
      include Helpers

      attr_accessor :examples_hash, :example_value, :keys_of_value

      def initialize(exp, keys_of_value = nil, multiple: false)
        multiple ? self.examples_hash = exp : self.example_value = exp
        self.keys_of_value = keys_of_value
      end

      def process
        return example_value if example_value
        return unless examples_hash

        examples_hash.map do |(name, value)|
          value =
            if keys_of_value.present? && value.is_a?(Array)
              { value: Hash[keys_of_value.zip(value)] }
            elsif value.is_a?(Symbol) && value['$']
              RefObj.new(value.to_s.delete('$'), :example).process
            elsif value.is_a?(Hash) && value.key?(:value)
              value
            else
              { value: value }
            end

          [ name, value ]
        end.to_h
      end
    end
  end
end


__END__

# in a model
schemas:
  properties:
    name:
      type: string
      examples:
        name:
          $ref: http://example.org/petapi-examples/openapi.json#/components/examples/name-example

# in a request body:
  requestBody:
    content:
      'application/json':
        schema:
          $ref: '#/components/schemas/Address'
        examples:
          foo:
            summary: A foo example
            value: {"foo": "bar"}
          bar:
            summary: A bar example
            value: {"bar": "baz"}
      'application/xml':
        examples:
          xmlExample:
            summary: This is an example in XML
            externalValue: 'http://example.org/examples/address-example.xml'

# in a parameter
  parameters:
    - name: 'zipCode'
      in: 'query'
      schema:
        type: 'string'
        format: 'zip-code'
        examples:
          zip-example:
            $ref: '#/components/examples/zip-example'

# in a response
  responses:
    '200':
      description: your car appointment has been booked
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/SuccessResponse'
          examples:
            confirmation-success:
              $ref: '#/components/examples/confirmation-success'
