require 'spec_helper'
require 'dssl_helper'

RSpec.describe OpenApi::DSL do
  desc :route_base, subject: :paths do
    before_do { route_base 'examples' }
    make -> { api :action }, 'is not mapped to goods#action', _it { be_nil }

    make -> { api :index }, 'is mapped to examples#index', has_key!: :'examples/index'
    focus_on :'examples/index', :get, :tags, 0
    expect_it eq: 'Examples', desc: 'is a Examples api'

    after_do { route_base 'goods' }
  end


  desc :doc_tag do
    make -> do
      doc_tag name: :Other, desc: 'tag desc', external_doc_url: 'url'
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
      make -> { api :no_routing_action }, 'refuses to be generated', _it { be_nil }
    end

    context 'when this action can be accessed through multiple HTTP methods (set through `match`, like `GET|POST`)' do
      make -> { api :change_onsale }, 'matches and generate both HTTP methods',
           has_keys: { 'goods/{id}/change_onsale': %i[ post patch ] }
    end

    context 'when this action can be accessed through multiple HTTP methods (not set through `match`)' do
      make -> { api :update }, 'matches and generate both HTTP methods',
           has_keys: { 'goods/{id}': %i[ put patch ] }
    end
  end


  desc :api_dry, subject: :paths do
    context 'when using the default :all parameter' do
      make -> do
        api_dry { resp :success, 'success response' }
        api :create
        api :index
      end, 'makes all actions have a :success response',
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
