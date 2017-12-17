require 'spec_helper'
require 'generate_helper'

RSpec.describe OpenApi::DSL::ApiInfoObj do
  let(:default_in) { [:api, :action, 'test'] }
  let(:key_path) { %i[ paths goods/action get ] }

  ctx 'when doing nothing' do
    mk -> { }, then_it { is_expected.to eq summary: 'test', operationId: :action, tags: ['Goods'] }
  end


  desc :this_api_is_invalid!, key: :deprecated do
    mk -> { this_api_is_invalid! }, then_it { is_expected.to be_truthy }
    mk -> { this_api_is_under_repair! 'reason' }, then_it { is_expected.to be_truthy }

    context 'when doing nothing' do
      mk -> { }, then_it { is_expected.to be_nil }
    end
  end


  desc :desc do
    mk -> { desc 'description for api #action.' }, have_keys: :description

    context 'when uniting parameters\' descriptions' do
      let(:params) { subject[:parameters] }

      before_dsl! do
        desc '#action', name: 'name', age!: 'age', id: 'id'
        query :name, String
        query :age, Integer
        query :id, Integer, desc: 'override'
      end
      it { expect(params[0]).to include name: :name, description: 'name' }
      it { expect(params[1]).to include name: :age, description: 'age' }
      it { expect(params[2]).to include name: :id, description: 'override' }
    end
  end


  desc :param, key: :parameters, stru: %i[ name in required schema ] do
    mk -> do
      param :query, :page, Integer, :req
      param :query, :per, Integer, :req
    end, all_have_keys: its_structure

    describe '#_param_agent: [ header header! path path! query query! cookie cookie! ]' do
      #
    end
  end
end
