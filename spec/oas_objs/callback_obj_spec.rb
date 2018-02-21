require 'spec_helper'
require 'dssl_helper'

RSpec.describe OpenApi::DSL::CallbackObj do
  let(:dsl_in) { [:api, :action, 'test'] }
  get_and_dig_doc %i[ paths goods/action get callbacks myEvent ]

  ctx 'use correctly' do
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

  ctx 'use with runtime expression correctly' do
    api -> do
      query! :id, Integer
      data :callback_addr, String, pattern: /^http/

      callback :myEvent, :post, '{body callback_addr}/api/goods/{query id}' do
        response 200, 'success', :json, data: { name: String, description: String }
      end
    end, has_key: :'{$request.body#/callback_addr}/api/goods/{$request.query.id}'
  end
end
