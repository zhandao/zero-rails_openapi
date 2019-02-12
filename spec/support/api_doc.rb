class ApiDoc < Object
  include OpenApi::DSL

  class << self
    def undo_dry
      oas[:dry_blocks] = { }
    end

    def inherited(subclass)
      super
      subclass.class_eval do
        break unless self.name[/sController|sDoc/]
        route_base self.name.sub('Doc', '').downcase.gsub('::', '/') if self.name[/sDoc/]
      end
    end
  end
end
