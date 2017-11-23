class V2::GoodsDoc < BaseDoc
  open_api :index, 'GET list of goods.', builder: :index, # jbuilder templates is set in initializers/open_api.rb
           use: [ 'Token', :page, :rows ] do # use parameters write in AutoGenDoc#api_dry
           # skip: [ 'Token' ] do # you can also skip parameters
    desc 'listing goods',
         view!: 'search view, allows:<br/>',
         search_type!: 'search field, allows:<br/>'

    # Single `query`
    query :view, String, enum: {
        'all goods (default)': :all,
                'only online': :online,
               'only offline': :offline,
            'expensive goods': :expensive,
                'cheap goods': :cheap,
    }
    # Batch `query`
    do_query by: {
        :search_type => { type: String, enum: %w[ name creator category price ] },
              :value => String,
             :export => { type: Boolean, desc: 'export as Excel format', examples: {
                 :right_input => true,
                 :wrong_input => 'wrong input'
             }}
    }
  end


  open_api :create, 'POST create a good', builder: :success_or_not, use: 'Token' do
    form! 'for creating a good', data: {
               :name! => { type: String,  desc: 'good\'s name' },
        :category_id! => { type: Integer, desc: 'sub_category\'s id', npmt: true, range: { ge: 1 }, as: :cate  },
              :price! => { type: Float,   desc: 'good\'s price', range: { ge: 0 } },
        # -- optional
           :is_online => { type: Boolean, desc: 'it\'s online?' },
             :remarks => { type: String,  desc: 'remarks' },
            :pic_path => { type: String,  desc: 'picture url', is: :url },
    },
          exp_by:    %i[ name category_id price ],
          examples: {
              :right_input => [ 'good1', 6, 5.7 ],
              :wrong_input => [ 'good2', 0, -1  ]
          }
  end


  open_api :show, 'GET the specified Good.', builder: :show, use: [ 'Token', :id ]


  open_api :destroy, 'DELETE the specified Good.', builder: :success_or_not, use: [ 'Token', :id ]
end
