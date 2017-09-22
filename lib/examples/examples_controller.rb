class Api::V1::ExamplesController < Api::V1::BaseController

  apis_set 'ExamplesController\'s Apis' do
    schema :Dog           => [ { id!: Integer, name: String }, dft: { id: 1, name: 'pet' } ]
    path!  :PathCompId    => [ :id, Integer, desc: 'user id' ]
    query! :QueryCompUuid => [ :product_uuid, { uuid: String, time: 'int32' }, desc: 'product uuid' ]
    body!  :RqBodyComp    => [ :form ]
    resp   :RespComp      => [ 'bad request', :json ]
  end

  open_api_set %i[index show], 'common response' do
    response '567', 'query result export', :pdf, type: File
  end


  open_api :index, '(SUMMARY) this api blah blah ...' do
    this_api_is_invalid! 'this api is expired!'
    desc 'Optional multiline or single-line Markdown-formatted description <br/>',
         id:         'user id',
         email_addr: 'email_addr\'s desc'
    email = 'zero@zero-rails.org'

    query! :id,         Integer, enum: 0..5,     length: [1, 2], pattern: /^[0-9]$/, range: {gt:0, le:5}
    query! :done,       Boolean, must_be: false, default: true,  desc: 'must be false'
    query  :email_addr, String,  lth: :ge_3,     dft: email # is_a: :email

    # form! 'form', type: { id!: Integer, name: String }
    file :pdf, 'desc: the media type is application/pdf'
    response :success, 'success response', :json, type: :Dog
    security :ApiKeyAuth
  end

  open_api :show do
    param_ref :PathCompId, :QueryCompUuid
    response_ref '123': :RespComp, '223' => :RespComp
  end

end
