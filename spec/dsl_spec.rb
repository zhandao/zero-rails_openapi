require 'spec_helper'
require 'dssl_helper'

RSpec.describe OpenApi::DSL do
  desc :ctrl_path, subject: :paths do
    before_do { ctrl_path 'examples' }
    make -> { api :action }, 'should not be mapped to goods#action', _it { be_nil }

    make -> { api :index }, 'should be mapped to examples#index', has_key!: :'examples/index'
    focus_on :'examples/index', :get, :tags, 0
    expect_it eq: 'Examples', desc: 'should be a Examples api'

    after_do { ctrl_path 'goods' }
  end


  desc :apis_tag do
    make -> do
      apis_tag name: :Other, desc: 'tag desc', external_doc_url: 'url'
      api :action
    end, has_keys!: %i[ tags paths ]
    focus_on :tags, 0
    expect_its :name, eq: :Other
    expect_its :description, eq: 'tag desc'
    expect_its :externalDocs, eq: { description: 'ref', url: 'url' }

    focus_on :paths, :'goods/action', :get, :tags, 0
    expect_it eq: :Other
  end


  desc :api, subject: :paths do
    context 'when this action is not configured routing' do
      make -> { api :no_routing_action }, 'should refuse to be generated', _it { be_nil }
    end

    context 'when this action can be accessed through multiple HTTP methods (set through `match`, like `GET|POST`)' do
      make -> { api :change_onsale }, 'should match and generate both HTTP methods',
           has_keys: { 'goods/{id}/change_onsale': %i[ post patch ] }
    end

    context 'when this action can be accessed through multiple HTTP methods (not set through `match`)' do
      make -> { api :change_onsale }, 'should match the first HTTP method',
           has_keys: { 'goods/{id}/change_onsale': [:patch] }
    end
  end


  desc :api_dry, subject: :paths do
    context 'when using the default :all parameter' do
      make -> do
        api_dry { resp :success, 'success response' }
        api :create
        api :index
      end, 'should make all actions have a :success response',
           has_keys: { goods: [ get: [responses: [:success]], post: [responses: [:success]] ] }
    end

    context 'when the action is specified' do
      make -> do
        api_dry(:index) { resp :success, 'success response' }
        api :create
        api :index
      end, has_keys!: :goods
      focus_on :goods, :get
      expect_its :responses, has_keys: :success
      focus_on :goods, :post
      expect_its(:responses) { be_nil }
    end
  end
end
