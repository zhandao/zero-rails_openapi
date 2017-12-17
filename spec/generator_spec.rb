require 'spec_helper'
require 'support/open_api'

RSpec.describe OpenApi::Generator do
  describe '.routes_list' do
    subject { OpenApi::Generator.routes_list }
    it { is_expected.to have_keys 'goods' }

    let(:goods_routes) { subject['goods'] }
    it { expect(goods_routes).to include(http_verb: 'post|patch', path: 'goods/{id}/change_onsale', action_path: 'goods#change_online') }
  end

  describe '.get_actions_by_ctrl_path' do
    correct do
      let(:goods) { subject.get_actions_by_ctrl_path('goods') }
      it { expect(goods).to eq %w[ action change_online index create show update update destroy ] }
    end

    wrong do
      let(:wrong_path) { subject.get_actions_by_ctrl_path('wrong_path') }
      it { expect(wrong_path).to be_nil }
    end
  end

  describe '.find_path_httpverb_by' do
    correct do
      let(:change_online) { subject.find_path_httpverb_by('goods', 'change_online') }
      it { expect(change_online).to eq [ 'goods/{id}/change_onsale', 'post' ] }
    end

    wrong do
      let(:wrong_path) { subject.find_path_httpverb_by('wrong_path', 'index') }
      it { expect(wrong_path).to be_nil }

      let(:wrong_action) { subject.find_path_httpverb_by('goods', 'wrong_action') }
      it { expect(wrong_action).to be_nil }
    end
  end
end
