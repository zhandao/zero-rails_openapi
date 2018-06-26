require 'spec_dsl'

RSpec.describe OpenApi::DSL::Api do
  let(:dsl_in) { [:api, :action, 'test'] }
  get_and_dig_doc %i[ paths goods/action get ]

  ctx 'when doing nothing' do
    api -> { }, get: { summary: 'test', operationId: :action, tags: ['Goods'] }
  end


  desc :this_api_is_invalid!, subject: :deprecated do
    api -> { this_api_is_invalid! }, be: true
    api -> { this_api_is_under_repair! 'reason' }, be: true

    context 'when doing nothing' do
      api -> { }, then_it { be_nil }
    end
  end


  desc :desc do
    api -> { desc 'description for api #action.' }, has_key: :description

    context "when uniting parameters' description" do
      let(:params) { subject[:parameters] }

      before_dsl! do
        desc '#action', name: 'name', age!: 'age', id: 'id'
        query :name, String
        query :age, Integer
        query :id, Integer, desc: 'override'
      end
      it { expect(params[0]).to include name: :name, description: 'name' }
      it { expect(params[1]).to include name: :age, description: 'age' }
      it { expect(params[2]).to include name: :id, description: 'override' }
    end
  end


  desc :param, subject: :parameters, stru: %i[ name in required schema ] do
    api -> do
      param :query, :page, Integer, :req
      param :query, :per, Integer, :opt
    end, all_have_its_structure

    context 'when passing `use` and `skip` to control parameters from `api_dry`' do
      before_do {
        api_dry do
          param :query, :page, Integer, :req
          param :query, :per, Integer, :opt
        end
      }

      make -> { api :action, use: [ ]      }, 'uses all', has_size: 2
      make -> { api :action, use: [:none]  }, then_it('only uses :none') { be_nil }
      make -> { api :action, use: [:page]  }, has_size: 1
      make -> { api :action, skip: [ ]     }, 'skips nothing', has_size: 2
      make -> { api :action, skip: [:page] }, has_size: 1

      make -> { api(:action, use: [:nothing]) { param :query, :page, Integer, :req } },
           'not skip the params inside block', has_size: 1
      make -> { api(:action, skip: [:per]) { param :query, :per, Integer, :req } },
           'not skip the params inside block', has_size: 2

      after_do { undo_dry }
    end

    describe '#_param_agent: [ header header! path path! query query! cookie cookie! ]' do
      correct do
        api -> { query :page ,Integer }, has_size!: 1
        focus_on :item_0
        expect_its :name, eq: :page
        expect_its :in, eq: 'query'
        expect_its :required, eq: false
        expect_its :schema, eq: { type: 'integer' }

        context 'when calling a bang agent' do
          api -> { header! :token, String }, take: 0
          focus_on :item_0, :required
          expect_it eq: true
        end

        context 'when defining combined schema' do
          api -> { cookie :a, not: [String] }, take: 0
          focus_on :item_0, :schema
          expect_it has_key: :not
        end

        context 'when re-calling through the same name' do
          api -> { query! :same_name, String; query :same_name, Integer }, 'overrides the older', take: 0
          it { expect(item_0).to include required: false }
          focus_on :item_0, :schema, :type
          expect_it eq: 'integer'
        end

        describe '#do_*:' do
          api -> { do_query by: { } }, then_it { be_nil }

          api -> { do_header by: { key: Integer, token!: String } }, has_size!: 2
          it { expect(item_0).to include name: :key, required: false }
          it { expect(item_1).to include name: :token, required: true }

          context 'when calling bang method' do
            api -> { do_path! by: { id: Integer, name: String } }, '---> has 2 required items:', has_size!: 2
            it { expect(item_0).to include name: :id, required: true}
            it { expect(item_1).to include name: :name, required: true}
          end

          context 'when passing common schema' do
            api -> { do_query by: { id: Integer, name: String }, pmt: true }, '---> has 2 required items:', has_size!: 2
            it { expect(item_0[:schema]).to include permit: true }
            it { expect(item_1[:schema]).to include permit: true }
          end
        end

        describe '#param_ref' do
          # before_do do components {
          #   query :QueryPage, :page, Integer
          #   path :PathId, :id, Integer
          # } end
          api -> { param_ref :QueryPage, :PathId, :NotExistCom }, has_size: 3, take: 2,
              desc: '---> has 3 ref, and the last:'
          it { expect(item_2[:$ref]).to eq '#/components/parameters/NotExistCom' }
        end
      end

      wrong 'no type and not combined schema' do
        api -> { query :wrong }, then_it { be_nil }
      end
    end


    desc :request_body, subject: :requestBody, stru: %i[ required description content ]  do
      api -> { request_body :req, :json }, has_its_structure

      describe '#_request_body_agent: [ body body! ]' do
        api -> { body :json, data: { name: 'test' } }, has_its_structure!
        it { expect(required).to be_falsey }
        it { expect(description).to eq '' }
        it { expect(content).to have_keys 'application/json': [ schema: %i[ type properties ] ] }

        context 'when calling the bang agent' do
          api -> { body! :json }, include: { required: true }
        end

        context 'when re-calling through different media-type' do
          api -> { body :json; body :xml }, 'merge together', has_key!: :content
          it { expect(content.size).to eq 2 }
        end

        context 'when re-calling through the same media-type' do
          api -> do
            body  :json, data: { :param_a! => String }
            body! :json, data: { :param_b  => Integer }
            body! :json, data: { :param_c! => Integer }
          end, have_key!: %i[ required content ]
          it { expect(required).to be_falsey }
          focus_on :content, :'application/json', :schema
          expect_its :required, eq: %w[ param_a param_c ]
          expect_its :properties, 'fusion together', has_keys: %i[ param_a param_b param_c ]
        end

        describe '#form and #form!' do
          api -> { form data: { name: 'test' } }, has_its_structure!
          it { expect(required).to be_falsey }
          it { expect(content).to have_keys 'multipart/form-data': [ schema: %i[ type properties ] ] }

          context 'when calling the bang method' do
            api -> { form! data: { } }, include: { required: true }
          end

          describe '#data' do
            api -> { data :uid, String }, has_its_structure!
            it { expect(required).to be_falsey }
            focus_on :content, :'multipart/form-data', :schema, :properties, :uid
            expect_its :type, eq: 'string'

            context 'when calling it multiple times' do
              api -> do
                data :uid, String
                data :name, String
              end, has_its_structure!
              focus_on :content, :'multipart/form-data', :schema, :properties, desc: 'fusion in form-data:'
              expect_it has_keys: %i[ uid name ]
            end
          end
        end

        describe '#file and #file!' do
          api -> { file :ppt }, has_its_structure!
          focus_on :content
          expect_it has_key: :'application/vnd.ms-powerpoint'

          step_into :'application/vnd.ms-powerpoint', :schema, :format
          expect_it eq: OpenApi::Config.file_format

          context 'when calling the bang method' do
            api -> { file! :doc }, include: { required: true }
          end
        end
      end

      describe '#body_ref' do
        # before_do do components {
        #   body :BodyA => [:xml ]
        #   body :BodyB => [:ppt ]
        # } end
        api -> { body :json; body_ref :BodyA; body_ref :BodyB }, 'is the last ref',
            include: { :$ref => '#/components/requestBodies/BodyB' }
      end
    end


    desc :response, subject: :responses do
      api -> do
        response :unauthorized, 'invalid token', :json
        response :bad_request, 'parameter validation failed'
      end, has_keys!: %i[ unauthorized bad_request ]
      focus_on :unauthorized
      expect_its :description, eq: 'invalid token'
      expect_its :content, has_keys: :'application/json'

      context 'when re-calling through the same code and media-type' do
        api -> do
          response :success, 'success desc1', :json, data: { name: String }
          response :success, 'success desc2', :json, data: { age: Integer }
        end, has_key!: :success
        focus_on :success
        expect_its :description, eq: 'success desc1', desc: 'not cover the older'
        step_into :content, :'application/json', :schema, :properties, desc: 'fusion together:'
        expect_it has_keys: %i[ name age ]
      end

      describe '#response_ref' do
        correct 'passing a code-to-refkey mapping hash' do
          api -> { response_ref unauthorized: :UnauthorizedResp, bad_request: :BadRequestResp },
              has_keys!: %i[ unauthorized bad_request ]
          it { expect(bad_request).to include :$ref => '#/components/responses/BadRequestResp' }
        end
      end
    end


    desc :security_require, subject: :security do
      api -> { auth :Token }, has_size!: 1
      it { expect(item_0).to eq Token: [ ] }
    end


    desc :callback, subject: :callbacks do
      api -> do
        callback :myEvent, :post, 'localhost:3000/api/goods' do
          query :name, String
          data :token, String
          response 200, 'success', :json, data: { name: String, description: String }
        end
      end, has_key!: :myEvent
      focus_on :myEvent, :'localhost:3000/api/goods', :post
      expect_it has_keys: %i[ parameters requestBody responses ]

      context 'when using with runtime expression' do
        api -> do
          query! :id, Integer
          data :callback_addr!, String, pattern: /^http/

          callback :myEvent, :post, '{body callback_addr}/api/goods/{query id}' do
            response 200, 'success', :json, data: { name: String, description: String }
          end
        end, has_key: { myEvent: [:'{$request.body#/callback_addr}/api/goods/{$request.query.id}'] }
      end

      context 'when define multiple callbacks' do
        api -> do
          callback :Event1, :post, 'url1'
          callback :Event1, :get,  'url1'
          callback :Event2, :get,  'url2'
        end, has_key!: { Event1: [:url1], Event2: [:url2] }
        focus_on :Event1, :url1
        expect_it has_keys: %i[ post get ]
      end
    end


    desc :server, subject: :servers, stru: %i[ url description ] do
      api -> { server 'http://localhost:3000', desc: 'Internal staging server for testing' },
          all_have_keys: its_structure, has_size: 1
    end


    desc :order, subject: :parameters do
      context 'when using in .api' do
        api -> do
          query :page, String
          path  :id, Integer
          order :id, :page
        end, has_size!: 2
        it { expect(item_0).to include name: :id }
        it { expect(item_1).to include name: :page }
      end

      context 'when using in .api_dry' do
        before_do! do
          api_dry do
            header :token, String
            path   :id, Integer
            order :id, :name, :age, :token, :remarks
          end

          api :action do
            query :remarks, String
            query :name, String
            query :age, String
          end

          undo_dry
        end

        focus_on :subject, desc: '`order` will auto generate `use` and `skip`, so:'
        expect_it { have_size 5 }
        expect_its(0) { include name: :id }
        expect_its(4) { include name: :remarks }
      end
    end


    desc :param_examples, subject: :examples do
      context 'when calling it normally' do
        api -> do
          examples %i[ id name ], {
              :right_input => [ 1, 'user'],
              :wrong_input => [ -1, ''   ],
              :example_ref => :'$InputExample'
          }
        end, has_size!: 3
        it { expect(item_0).to eq right_input: { value: { id: 1, name: 'user' } } }
        it { expect(item_2).to eq example_ref: { :$ref => '#/components/InputExamples/example' } }
      end

      context 'when passing default :all to exp_  by' do
        correct 'have defined specified parameters' do
          api -> do
            query :id, String
            query :name, String
            examples :all, { right_input: [ 1, 'user', 'extra value'] }
          end, has_size!: 1
          it { expect(item_0).to eq right_input: { value: { id: 1, name: 'user' } } }
        end

        wrong 'have not defined specified parameters' do
          api -> do
            examples :all, { right_input: [ 1, 'user'] }
          end, has_size!: 1
          it { expect(item_0).to eq right_input: { value: [ 1, 'user'] } }
        end
      end
    end
  end
end
