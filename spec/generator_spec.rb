require 'support/open_api'

RSpec.describe OpenApi::Router do
  describe '.routes_list' do
    subject { OpenApi::Router.routes_list }
    it { is_expected.to have_keys 'goods' }

    let(:goods_routes) { subject['goods'] }
    it { expect(goods_routes).to include(http_verb: 'post|patch', path: 'goods/{id}/change_onsale', action_path: 'goods#change_onsale') }
  end

  describe '.get_actions_by_route_base' do
    correct do
      let(:goods) { subject.get_actions_by_route_base('goods') }
      it { expect(goods).to eq %w[ action change_onsale index create show update update destroy ] }
    end

    wrong do
      let(:wrong_path) { subject.get_actions_by_route_base('wrong_path') }
      it { expect(wrong_path).to be_nil }
    end
  end

  describe '.find_path_httpverb_by' do
    correct do
      let(:change_onsale) { subject.find_path_httpverb_by('goods', 'change_onsale') }
      it { expect(change_onsale).to eq [ 'goods/{id}/change_onsale', 'post' ] }
    end

    wrong do
      let(:wrong_path) { subject.find_path_httpverb_by('wrong_path', 'index') }
      it { expect(wrong_path).to be_nil }

      let(:wrong_action) { subject.find_path_httpverb_by('goods', 'wrong_action') }
      it { expect(wrong_action).to be_nil }
    end
  end
end
