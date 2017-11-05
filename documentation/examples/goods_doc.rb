class V2::GoodsDoc < BaseDoc

  open_api :index, 'Get list of Goods.', builder: :index,
           use: [ 'Token' ] do # use parameters write in AutoGenDoc#api_dry
           # skip: %i[ Token ] do # you can also skip parameters
    desc 'listing Goods',
         view!: 'search view, allows:：<br/>',
         search_type!: 'search field, allows：<br/>'

    query :view, String, enum: {
        'all goods (default)': :all,
                'only online': :online,
               'only offline': :offline,
            'expensive goods': :expensive,
                'cheap goods': :cheap,
    }
    # query :search_type, String, enum: %w[name creator category price]
    do_query by: {
        :search_type => { type: String, enum: %w[ name creator category price ] },
        :export => { type: Boolean, desc: 'export as Excel format', examples: {
            :right_input => true,
            :wrong_input => 'wrong input'
        }}
    }
  end


  open_api :create, 'Create a Good', builder: :success_or_not, use: 'Token' do
    form! 'for creating a good', data: {
               :name! => { type: String,  desc: 'good\'s name' },
        :category_id! => { type: Integer, desc: 'sub_category\'s id', npmt: true, range: { ge: 1 }, as: :cate  },
              :price! => { type: Float,   desc: 'good\'s price', range: { ge: 0} },
        # -- optional
           :is_online => { type: Boolean, desc: 'it\'s online?' },
             :remarks => { type: String,  desc: 'remarks' },
            :pic_path => { type: String,  desc: 'picture url', is: :url },
    }, exp_by: %i[ name category_id price ],
          examples: {
              :right_input => [ 'good1', 6, 5.7 ],
              :wrong_input => [ 'good2', 0, -1  ]
          }
  end


  open_api :show, 'Show a Good.', builder: :show, use: [ 'Token', :id ]


  open_api :destroy, 'Delete a Good.', builder: :success_or_not, use: [ 'Token', :id ]
end
