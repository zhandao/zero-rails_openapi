class Api::V1::ExamplesController < Api::V1::BaseController
  apis_tag name: 'ExampleTagName', desc: 'ExamplesController\'s APIs'

  components do
    schema :DogSchema => [ String, dft: 'doge' ]
    schema :PetSchema => [ not: [ Integer, Boolean ] ]
    query! :UidQuery  => [ :uid, String, desc: 'user uid' ]
    path!  :IdPath    => [ :id, Integer, desc: 'product id' ]
    resp   :BadRqResp => [ 'bad request', :json ]
  end


  api_dry %i[ index show ], 'common parts of :index and :show' do
    header!  :Token, String
    response 1000, 'data export', :pdf, type: File
  end


  api :index, 'GET examples', use: :Token do
    this_api_is_invalid! 'do not use!'
    desc '**GET** list of examples,<br/>and get the status 200.',
         id:    'user id',
         email: 'email addr\'s desc'
    email = 'a@b.c'

    query! :count, Integer, enum: 0..5,     length: [1, 2], pattern: /^[0-9]$/, range: { gt: 0, le: 5 }
    query! :done,  Boolean, must_be: false, default: true,  desc: 'must be false'
    query  :email, String,  lth: :ge_3,     default: email  # is_a: :email
    file   :pdf, 'upload a file: the media type should be application/pdf'

    query :test_type, type: String
    query :combination, one_of: [ :DogSchema, String, { type: Integer, desc: 'integer input'}]
    form data: {
        :combination => { any_of: [ Integer, String ] }
    }

    response :success, 'success response', :json#, data: :Pet
    security :Token

    resp 200, '', :json, data: {
        a: String
    }
  end


  api :show, skip: :Token do
    param_ref    :IdPath, :UidQuery
    response_ref 400 => :BadRqResp
  end


  api :create do
    form! data: {
            :name! => String, # <= schema_type is `String`
        :password! => { type: String, pattern: /[0-9]{6,10}/, desc: 'password' },
        # optional
          :remarks => { type: String, desc: 'remarks' }, # <= schema_type is `String`, and schema_hash is { desc: '..' }
    }
  end
end
