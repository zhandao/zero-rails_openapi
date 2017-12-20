require 'spec_helper'
require 'dssl_helper'

RSpec.describe OpenApi::DSL::SchemaObj do
  let(:default_in) { [:api, :action, 'test'] }
  let(:subject_key_path) { %i[ paths goods/action get parameters ] + [ 0, :schema ] }

  ctx 'when not pass schema type as Hash type' do
    api -> { query :id, Integer }, eq: { type: 'integer' }
    api -> { query :people, { name: String }, desc: '' }, then_it { include type: 'object' }
    api -> { query :people, { name: String } }, 'will not have key :schema cause cannot recognize schema type',
        raise: [NoMethodError, "undefined method `[]' for nil:NilClass"]
  end

  ctx 'when pass schema type as Hash type' do
    api -> { query :id, type: Integer }, eq: { type: 'integer' }
    api -> { query :people, type: { name: String } }, then_it { include type: 'object' }
  end

  desc :processed_type do
    context 'when not be one of the [Hash, Array, Symbol]' do
      context 'when in [ float double int32 int64 ]' do
        api -> { query :field, Float }, eq: { type: 'number', format: 'float' }
        api -> { query :field, 'double' }, eq: { type: 'number', format: 'double' }
        api -> { query :field, 'int32' }, eq: { type: 'integer', format: 'int32' }
      end

      context 'when in [ binary base64 ]' do
        api -> { query :field, 'binary' }, eq: { type: 'string', format: 'binary' }
      end

      context 'when be file' do
        api -> { query :field, 'file' }, eq: { type: 'string', format: OpenApi::Config.dft_file_format }
      end

      context 'when be datetime' do
        api -> { query :field, 'datetime' }, eq: { type: 'string', format: 'date-time' }
      end

      context 'when is string or constant (not the above)' do
        api -> { query :field, 'type' }, eq: { type: 'type' }
        api -> { query :field, ApiDoc }, eq: { type: 'api_doc' }
      end
    end

    context 'when be a Symbol' do
      api -> { query :field, :QueryPage }, 'should be a parameter ref', eq: { :$ref => '#components/schemas/QueryPage' }
    end

    context 'when be a Array' do
      api -> { query :field, Array[String] }, has_keys!: %i[ type items ]
      it { expect(type).to eq 'array' }
      it { expect(items).to eq type: 'string' }

      context 'when be a nested Array' do
        api -> { query :field, [[String]] }, has_keys!: %i[ type items ]
        it { expect(items).to have_keys %i[ type items ] }

        context 'with CombinedSchema' do
          api -> { query :field, [one_of: [String, Integer]] }, has_keys!: %i[ type items ]
          it { expect(items).to have_keys :oneOf }
        end

        wrong 'want combined schema, but without CombinedSchema writing' do
          api -> { query :field, [String, Integer] }, has_keys!: %i[ type items ]
          it('should only take the first type') { expect(items).to eq type: 'string' } # TODO: default to be one_of
          it { expect(items).not_to have_keys %i[ oneOf anyOf allOf not ] }
        end
      end
    end

    context 'when be a Hash' do
      api -> { query :field, type: { name: String, age: Integer } }, has_keys!: %i[ type properties ]
      it { expect(type).to eq 'object' }
      it { expect(properties).to have_keys %i[ name age ] }
    end
  end
end
