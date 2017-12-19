require 'spec_helper'
require 'dssl_helper'

RSpec.describe OpenApi::DSL::SchemaObj do
  let(:default_in) { [:api, :action, 'test'] }
  let(:subject_key_path) { %i[ paths goods/action get parameters ] + [ 0, :schema ] }

  ctx 'test' do
    mk -> { query :id, Integer }, eq: { type: 'integer' }
  end
end
