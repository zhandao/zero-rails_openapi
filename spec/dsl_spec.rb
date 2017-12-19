require 'spec_helper'
require 'generate_helper'

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

    after_do { @_api_infos = { } }
  end


  desc :api, subject: :paths do
    context 'when this action is not configured routing' do
      make -> { api :no_routing_action }, 'should refuse to be generated', _it { be_nil }
    end


  end
end
