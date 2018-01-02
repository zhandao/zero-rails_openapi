class ApiDoc < Object
  include OpenApi::DSL

  class << self
    def undo_dry
      @zro_dry_blocks = nil
    end

    def inherited(subclass)
      super
      subclass.class_eval do
        break unless self.name.match?(/sController|sDoc/)
        route_base self.name.sub('Doc', '').downcase.gsub('::', '/') if self.name.match?(/sDoc/)
      end
    end
  end
end
