require 'open_api/generator'

# Usage: add `include AutoGenDSL` to base controller.
module AutoGenDSL
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def inherited(subclass)
      super
      subclass.class_eval do
        break unless self.name.match? /sController|sDoc/
        ctrl_path "api/#{self.name.sub('Doc', '').downcase.gsub('::', '/')}" if self.name.match? /sDoc/
        open_api_dry
      end
    end

    private

    def open_api_dry
      ctrl_path = try(:controller_path) || instance_variable_get('@_ctrl_path')
      ::OpenApi::Generator.get_actions_by_ctrl_path(ctrl_path)&.each do |action|
        api_dry action do
          # Token in Header
          if !action_path.match?(/NoVerificationController/) && !%w[create login].include?(action)
            header! 'Token', String, desc: 'user token'
          end

          # Common :index parameters
          if !action_path.match?(/NotDRYController/) && action == 'index'
            query :page,     Integer, desc: 'page'
            query :per_page, Integer, desc: 'per'
          end

          # OAS require at least one response on each api.
          default_response 'default response', :json
        end
      end
    end
  end
end
