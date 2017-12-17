require 'spec_helper'
require 'generate_helper'

RSpec.describe OpenApi::DSL::Components do
  let(:default_in) { [:components] }
  let(:key_path) { nil }

  desc :schema, key: :schemas do
    correct do
      mk -> { schema :SchemaA, String; schema :SchemaZ, String }, doc_will_has_keys: { schemas: %i[ SchemaA SchemaZ ] }

      mk -> { schema :SchemaA, String                           }, eq: { SchemaA: { type: 'string'} }
      mk -> { schema :SchemaA, type: Integer                    }, eq: { SchemaA: { type: 'integer'} }
      mk -> { schema :SchemaB => [ String ]                     }, eq: { SchemaB: { type: 'string'} }
      mk -> { schema :SchemaC => [ type: String, desc: 'test' ] }, eq: { SchemaC: { type: 'string', description: 'test' } }

      context 'when defining combined schema' do
        mk -> { schema :SchemaD => [ one_of: [String] ] }, have_keys: { SchemaD: [:oneOf] }
      end
    end

    wrong 'no type and not combined schema' do
      mk -> { schema :SchemaW }, then_it { is_expected.to be_nil }
    end
  end


  desc :example, key: :examples do
    mk -> { example :ExampleA, { }; example :ExampleZ, { } }, doc_will_has_keys: { examples: %i[ ExampleA ExampleZ ] }
    mk -> { example :ExampleA, { name: 'BeiGou' } }, eq: { ExampleA: [{ name: { value: 'BeiGou' } }] }
  end


  desc :param, key: :parameters, stru: %i[ name in required schema ] do
    mk -> do
      param :QueryA, :query, :page, Integer, :req
      param :QueryZ, :query, :rows, Integer, :req
    end, doc_will_has_keys: { parameters: %i[ QueryA QueryZ ] }

    describe '#_param_agent: [ header header! path path! query query! cookie cookie! ]' do
      correct do
        mk -> { query :QueryPage, :page ,Integer }, have_keys!: { QueryPage: its_structure }
        focus_on :QueryPage
        expect_its :name, eq: :page
        expect_its :in, eq: 'query'
        expect_its(:required) { be_falsey }
        expect_its :schema, eq: { type: 'integer' }

        mk -> { path :PathId => [ :id, Integer ] }, have_keys: { PathId: its_structure << { schema: [:type] } }

        context 'when calling a bang agent' do
          mk -> { header! :HeaderToken => [ :token, String ] }, have_key!: :HeaderToken
          it { expect(header_token[:required]).to be_truthy }
        end

        context 'when defining combined schema' do
          mk -> { cookie :CookieA => [ :a, not: [String] ] }, have_keys: { CookieA: its_structure << { schema: [:not] } }
        end
      end

      wrong 'no type and not combined schema' do
        mk -> { query! :QueryW, :wrong }, then_it { is_expected.to be_nil }
      end
    end
  end


  desc :request_body, key: :requestBodies, stru: %i[ required description content ] do
    mk -> { request_body :Body, :req, :json }, doc_will_has_keys: { requestBodies: %i[ Body ] }

    describe '#_request_body_agent: [ body body! ]' do
      mk -> { body :BodyA, :json, data: { name: 'test' } }, have_keys!: { BodyA: its_structure }
      focus_on :BodyA
      expect_its(:required) { be_falsey }
      expect_its :description, eq: ''
      expect_its :content, have_keys: { 'application/json': [ schema: %i[ type properties ] ] }

      mk -> { body :BodyB => [:json] }, have_keys!: { BodyB: its_structure }

      context 'when calling a bang agent' do
        mk -> { body! :BodyC => [ :json ] }, have_key!: :BodyC
        it { expect(body_c[:required]).to be_truthy }
      end

      context 'when re-calling through different component_keys' do
        mk -> do
          body :BodyD => [:xml ]
          body :BodyE => [:xml ]
          body :BodyF => [:ppt ]
        end, 'should merge together', have_keys: %i[ BodyD BodyE BodyF ]
      end

      context 'when re-calling through the same component_key' do
        mk -> do
          body  :SameBody => [:json, data: { :param_a! => String } ]
          body! :SameBody => [:json, data: { :param_b => Integer } ]
        end, have_keys!: { SameBody: its_structure }
        it { expect(same_body[:required]).to be_falsey }

        focus_on :SameBody, :content, :'application/json', :schema
        expect_its :required, eq: ['param_a']
        expect_its :properties, 'should fusion together', have_keys: %i[ param_a param_b ]
      end
    end
  end


  desc :response, key: :responses, stru: %i[ description content ] do
    mk -> do
      response :RespA, 'invalid token'
      response :RespZ, 'parameter validation failed'
    end, doc_will_has_keys: { responses: %i[ RespA RespZ ] }

    mk -> { resp :RespA => ['desc', :json] }, have_keys!: { RespA: its_structure }
    focus_on :RespA
    expect_its :description, eq: 'desc'
    expect_its :content, have_keys: :'application/json'
  end


  desc :security_scheme, key: :securitySchemes, stru: %i[  ] do
    mk -> do
      auth_scheme :OAuth, type: 'oauth2', flows: { implicit: {
          authorizationUrl: 'https://example.com/api/oauth/dialog',
          scopes: { 'write:pets': 'modify pets in your account',  'read:pets': 'read your pets' }
      } }, desc: 'desc'
    end, doc_will_has_keys: { securitySchemes: %i[ OAuth ] }

    describe '#base_auth' do
      mk -> { base_auth :BaseAuth }, eq: { BaseAuth: { type: 'http', scheme: 'basic' }}
    end

    describe '#bearer_auth' do
      mk -> { bearer_auth :Token }, eq: { Token: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }}
    end

    describe '#api_key' do
      mk -> { api_key :ApiKey => [ field: 'field_name', desc: 'desc' ] },
         eq: { ApiKey: { type: 'apiKey', name: 'field_name', in: 'header', description: 'desc' } }
    end
  end
end
