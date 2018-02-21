require 'spec_helper'
require 'dssl_helper'

RSpec.describe OpenApi::DSL::CallbackObj do
  let(:dsl_in) { [:api, :action, 'test'] }
  get_and_dig_doc %i[ paths goods/action get callbacks myEvent ]

  ctx 'correctly' do
    api -> do
      callback :myEvent, :post, 'localhost:3000/api/goods' do
        query :name, String
        data :token, String
        response 200, 'success', :json, data: { name: String, description: String }
      end
    end, has_key!: :'localhost:3000/api/goods'

    focus_on :'localhost:3000/api/goods', :post
    expect_it has_keys: %i[ parameters requestBody responses ]
  end
end
