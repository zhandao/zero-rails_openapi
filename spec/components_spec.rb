require 'spec_dsl'

RSpec.describe OpenApi::DSL::Components do
  get_and_dig_doc [:components]
  let(:dsl_in) { [:components] }

  desc :schema, subject: :schemas do
    correct do
      mk -> { schema :SchemaA, String; schema :SchemaZ, String }, doc_will_has_keys: { schemas: %i[ SchemaA SchemaZ ] }

      mk -> { schema :SchemaA, String                           }, get: { SchemaA: { type: 'string'} }
      mk -> { schema :SchemaA, type: Integer                    }, get: { SchemaA: { type: 'integer'} }
      mk -> { schema :SchemaB => [ String ]                     }, get: { SchemaB: { type: 'string'} }
      mk -> { schema :SchemaC => [ type: String, desc: 'test' ] }, get: { SchemaC: { type: 'string', description: 'test' } }

      context 'when defining combined schema' do
        mk -> { schema :SchemaD => [ one_of: [String] ] }, has_keys: { SchemaD: [:oneOf] }
      end
    end

    wrong 'no type and not combined schema' do
      mk -> { schema :SchemaW }, then_it { be_nil }
    end
  end


  desc :example, subject: :examples do
    mk -> { example :ExampleA, { }; example :ExampleZ, { } }, doc_will_has_keys: { examples: %i[ ExampleA ExampleZ ] }
    mk -> { example :ExampleA, { name: 'BeiGou' } }, get: { ExampleA: [{ name: { value: 'BeiGou' } }] }
  end


  desc :param, subject: :parameters, stru: %i[ name in required schema ] do
    mk -> do
      param :QueryA, :query, :page, Integer, :req
      param :QueryZ, :query, :rows, Integer, :req
    end, doc_will_has_keys: { parameters: %i[ QueryA QueryZ ] }

    describe '#_param_agent: [ header header! path path! query query! cookie cookie! ]' do
      correct do
        mk -> { query :QueryPage, :page, Integer }, has_keys!: { QueryPage: its_structure }
        focus_on :QueryPage
        expect_its :name, eq: :page
        expect_its :in, eq: 'query'
        expect_its :required, eq: false
        expect_its :schema, eq: { type: 'integer' }

        mk -> { path :PathId => [ :id, Integer ] }, has_keys: { PathId: its_structure << { schema: [:type] } }

        context 'when calling a bang agent' do
          mk -> { header! :HeaderToken => [ :token, String ] }, has_key!: :HeaderToken
          it { expect(header_token[:required]).to be_truthy }
        end

        context 'when defining combined schema' do
          mk -> { cookie :CookieA => [ :a, not: [String] ] }, has_keys: { CookieA: its_structure << { schema: [:not] } }
        end
      end

      wrong 'no type and not combined schema' do
        mk -> { query! :QueryW, :wrong }, then_it { be_nil }
      end
    end
  end


  desc :request_body, subject: :requestBodies, stru: %i[ required description content ] do
    mk -> { request_body :Body, :req, :json }, doc_will_has_keys: { requestBodies: %i[ Body ] }

    describe '#_request_body_agent: [ body body! ]' do
      mk -> { body :BodyA, :json, data: { name: 'test' } }, has_keys!: { BodyA: its_structure }
      focus_on :BodyA
      expect_its :required, eq: false
      expect_its :description, eq: ''
      expect_its :content, has_keys: { 'application/json': [ schema: %i[ type properties ] ] }

      mk -> { body :BodyB => [ :json ] }, has_keys!: { BodyB: its_structure }

      context 'when calling the bang agent' do
        mk -> { body! :BodyC => [ :json ] }, has_key!: :BodyC
        it { expect(body_c[:required]).to be_truthy }
      end

      context 'when re-calling through different component_keys' do
        mk -> do
          body :BodyD => [ :xml ]
          body :BodyE => [ :xml ]
          body :BodyF => [ :ppt ]
        end, 'merge together', has_keys: %i[ BodyD BodyE BodyF ]
      end

      context 'when re-calling through the same component_key' do
        mk -> do
          body  :SameBody => [ :json, data: { :param_a! => String } ]
          body! :SameBody => [ :json, data: { :param_b => Integer } ]
        end, have_keys!: { SameBody: its_structure }
        it { expect(same_body[:required]).to be_falsey }
        focus_on :SameBody, :content, :'application/json', :schema
        expect_its :required, eq: ['param_a']
        expect_its :properties, 'fusion together', has_keys: %i[ param_a param_b ]
      end
    end
  end


  desc :response, subject: :responses, stru: %i[ description content ] do
    mk -> do
      response :RespA, 'invalid token'
      response :RespZ, 'parameter validation failed'
    end, doc_will_has_keys: { responses: %i[ RespA RespZ ] }

    mk -> { resp :RespA => [ 'desc', :json ] }, has_keys!: { RespA: its_structure }
    focus_on :RespA
    expect_its :description, eq: 'desc'
    expect_its :content, has_keys: :'application/json'

    # The re-calling test see: api_info_obj_spec.rb
  end


  desc :security_scheme, subject: :securitySchemes, stru: %i[  ] do
    mk -> do
      auth_scheme :OAuth, type: 'oauth2', flows: { implicit: {
          authorizationUrl: 'https://example.com/api/oauth/dialog',
          scopes: { 'write:pets': 'modify pets in your account',  'read:pets': 'read your pets' }
      } }, desc: 'desc'
    end, doc_will_has_keys: { securitySchemes: %i[ OAuth ] }

    describe '#base_auth' do
      mk -> { base_auth :BaseAuth }, get: { BaseAuth: { type: 'http', scheme: 'basic' }}
    end

    describe '#bearer_auth' do
      mk -> { bearer_auth :Token }, get: { Token: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }}
    end

    describe '#api_key' do
      mk -> { api_key :ApiKey => [ field: 'field_name', desc: 'desc' ] },
         eq: { ApiKey: { type: 'apiKey', name: 'field_name', in: 'header', description: 'desc' } }
    end
  end
end
