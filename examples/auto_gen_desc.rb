class V1::GoodsDoc < BaseDoc
  api :index, 'GET list of goods.' do
    desc 'listing goods',
         view!: 'search view, allows:<br/>',
               # '1/ all goods (default)：all<br/>' \
               # '2/ only online：online<br/>' \
               # '3/ only offline：offline<br/>' \
               # '4/ expensive goods：expensive<br/>' \
               # '5/ cheap goods：cheap<br/>',
         search_type!: 'search field, allows:<br/>'
               # '1/ name<br/>2/ creator,<br/>3/ category<br/>4/ price<br/>'

    # Instead of:
    # query :view,        String, enum: %w[ all online offline expensive cheap ]
    query :view, String, enum!: {
        'all goods (default)': :all,
                'only online': :online,
               'only offline': :offline,
            'expensive goods': :expensive,
                'cheap goods': :cheap
    }
    query :search_type, String, enum: %w[ name creator category price ]
    # Same as:
    # query :search_type, String, desc!: 'search field, allows：<br/>',
    #       enum: %w[ name creator category price ]

    # TODO: Support `desc: '', auto_desc: true or %i[ enum must_be ]`
  end
end
