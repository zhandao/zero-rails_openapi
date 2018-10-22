RSpec.describe OpenApi::Config do
  before_config { open_api :zro, base_doc_classes: [ApiDoc] }

  describe '.open_api' do
    let(:docs) { OpenApi::Config.docs }
    it { expect(docs).to include(zro: { base_doc_classes: [ApiDoc] }) }

    context 'when adding a second doc' do
      before_config { open_api :doc2, base_doc_classes: [ApiDoc] }
      it { expect(docs).to have_keys :zro, :doc2 }
    end
  end

  let(:doc) { OpenApi::Config.docs[:zro] }
  subject { doc }

  describe '.info' do
    let(:info) { subject[:info] }

    before_config do
      info version: '0.0.1', title: 'APIs', desc: 'description', contact: {
          name: 'API Support', url: 'http://www.skippingcat.com', email: 'x@skippingcat.com'
      }
    end
    it { is_expected.to have_keys :base_doc_classes, info: %i[ version title description contact ] }
    it { expect(info[:contact]).to have_keys :name, :url, :email }
  end

  describe '.server' do
    let(:servers) { subject[:servers] }

    before_config { server 'http://localhost:3000', desc: 'Internal staging server for testing' }
    it { is_expected.to have_keys :base_doc_classes, :servers }
    it { expect(servers.first).to have_keys :url, :description }
  end

  describe '.security_scheme' do
    let(:security_schemes) { subject[:securitySchemes] }

    before_config do
      auth_scheme :OAuth, type: 'oauth2', flows: { implicit: {
          authorizationUrl: 'https://example.com/api/oauth/dialog',
          scopes: { 'write:pets': 'modify pets in your account',  'read:pets': 'read your pets' }
      } }, desc: 'desc'
    end
    it { is_expected.to have_keys :base_doc_classes, securitySchemes: [ OAuth: %i[ description type flows ] ] }

    describe '.base_auth' do
      before_config { base_auth :BaseAuth }
      it { expect(security_schemes[:BaseAuth]).to eq(type: 'http', scheme: 'basic') }
    end

    describe '.bearer_auth' do
      before_config { bearer_auth :Token }
      it { expect(security_schemes[:Token]).to eq(type: 'http', scheme: 'bearer', bearerFormat: 'JWT') }
    end

    describe '.api_key' do
      before_config { api_key :ApiKey, field: 'field_name', desc: 'desc' }
      it { expect(security_schemes[:ApiKey]).to eq(type: 'apiKey', name: 'field_name', in: 'header', description: 'desc') }
    end
  end

  describe '.global_security_require' do
    let(:global_security) { subject[:global_security] }

    before_config { global_auth :Token }
    it { expect(global_security).to eq [{ Token: [] }] }
  end
end
