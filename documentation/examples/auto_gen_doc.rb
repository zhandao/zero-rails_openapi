require 'open_api/generator'

# Usage: add `include AutoGenDoc` to base controller.
module AutoGenDoc
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
          # Token in Header\
          with_out_token = %w[
              users#login users#create
          ]
          unless action_path.match? Regexp.new with_out_token.join('|')
            # if !action_path.match?(/NoVerificationController/) && !%w[create login].include?(action)
            header! 'Token', String, desc: 'user token'
          end

          # Common :index parameters
          # if !action_path.match?(/NotDRYController/) && action == 'index'
          #   query :page,     Integer, desc: 'page', range: { ge: 1 }, dft: 1
          #   query :per_page, Integer, desc: 'per', range: { ge: 1 }, dft: 10
          # end

          # OAS require at least one response on each api.
          # default_response 'default response', :json
          response '200', 'success', :json, type: {
              code:      { type: Integer, dft: 200 },
              msg:       { type: String,  dft: 'success' },
              total:     { type: Integer },
              timestamp: { type: Integer },
              language:  { type: String, dft: 'Ruby' },
              data:      { type: [Object], dft: [ ] }
          }

          # automatically generate responses based on the agreed error class.
          # api/v1/examples#index => ExamplesError
          error_class_name = action_path.split('#').first.split('/').last.camelize.concat('Error')
          error_class = Object.const_get(error_class_name) rescue next
          errors = error_class.errors
          cur_errs = (errors[action.to_sym] || []) + (errors[:_public] || [ ])
          cur_errs.each do |error|
            info = error_class.send(error, :info)
            response info[:code], info[:msg]
          end
        end
      end
    end
  end
end