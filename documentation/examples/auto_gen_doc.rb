require 'open_api/generator'

# Usage: add `include AutoGenDoc` to your base controller.
module AutoGenDoc
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def inherited(subclass)
      super
      subclass.class_eval do
        break unless self.name.match?(/sController|sDoc/)
        ctrl_path self.name.sub('Doc', '').downcase.gsub('::', '/') if self.name.match?(/sDoc/)
        open_api_dry
      end
    end

    private

    def open_api_dry
      ctrl_path = try(:controller_path) || instance_variable_get('@_ctrl_path')
      ::OpenApi::Generator.get_actions_by_ctrl_path(ctrl_path)&.each do |action|
        api_dry action do
          header! 'Token', String, desc: 'user token'

          # Common :index parameters
          if action == 'index'
            query :page, Integer, desc: 'page, greater than 1', range: { ge: 1 }, dft: 1
            query :rows, Integer, desc: 'data count per page',  range: { ge: 1 }, dft: 10
          end

          # Common :show parameters
          if action == 'show'
            path! :id, Integer, desc: 'id'
          end

          # Common :destroy parameters
          if action == 'destroy'
            path! :id, Integer, desc: 'id'
          end

          # Common :update parameters
          if action == 'update'
            path! :id, Integer, desc: 'id'
          end

          ### Common responses
          # OAS require at least one response on each api.
          # default_response 'default response', :json
          model = Object.const_get(action_path.split('#').first.split('/').last[0..-2].camelize) rescue nil
          type = action.in?(%w[ index show ]) ? Array[load_schema(model)] : String
          response '200', 'success', :json, type: {
              code: { type: Integer, dft: 200 },
               msg: { type: String,  dft: 'success' },
              data: { type: type }
          }


          ### Automatically generate responses based on the agreed error class.
          #   The business error-class's implementation see:
          #     https://github.com/zhandao/zero-rails/blob/master/lib/business_error/dsl.rb
          #   It's usage see:
          #     https://github.com/zhandao/zero-rails/blob/master/app/_docs/api_error.rb
          #   Then, the following code will auto generate error responses by
          #     extracting the specified error classes info, for example,
          #     in ExamplesError: `mattr_reader :name_not_found, 'can not find the name', 404`
          #     will generate: `"404": { "description": "can not find the name" }`
          ###
          # # api/v1/examples#index => ExamplesError
          # error_class_name = action_path.split('#').first.split('/').last.camelize.concat('Error')
          # error_class = Object.const_get(error_class_name) rescue next
          # cur_api_errs = error_class.errors.values_at(action.to_sym, :private, :_public).flatten.compact.uniq
          # cur_api_errs.each do |error|
          #   info = error_class.send(error, :info)
          #   response info[:code], info[:msg]
          # end
        end
      end
    end
  end
end
