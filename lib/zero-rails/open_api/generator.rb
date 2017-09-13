module ZeroRails
  module OpenApi
    module Generator
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def generate_docs(api_name = nil)
          Rails.application.eager_load!
          if api_name.present?
            generate_doc api_name
          else
            ZeroRails::OpenApi.apis.keys.map { |api| generate_doc api }
          end
        end

        def generate_doc(api_name)
          settings = ZeroRails::OpenApi.apis[api_name]
          doc = { openapi: '3.0.0' }.merge(settings.slice :info, :servers).merge({
                  security: settings[:global_security],
                  tags: [ ], paths: { }, components: { }
                })
          if gsc = settings[:global_security_schemes]; doc[:components][:securitySchemes] = gsc; end

          settings[:root_controller].descendants.each do |ctrl|
            doc[:paths].merge! ctrl.instance_variable_get('@api_infos')
            doc[:tags] << ctrl.instance_variable_get('@ctrl_infos')
            doc[:components] # TODO
          end
          doc.reject { |_,v| v.blank? }
        end

        def write_docs
          docs = generate_docs
          puts docs
        end
      end

      def self.generate_routes_list
        # ref https://github.com/rails/rails/blob/master/railties/lib/rails/tasks/routes.rake
        require './config/routes'
        all_routes = Rails.application.routes.routes
        require "action_dispatch/routing/inspector"
        inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)

        inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, nil).split("\n").drop(1).map do |line|
          infos = line.match(/[A-Z].*/).to_s.split(' ') # => [GET, /api/v1/examples/:id, api/v1/examples#index]
          {
              http_verb: infos[0].downcase, # => "get"
              path: infos[1].sub('(.:format)', '').split('/').map do |item|
                      item.match?(/:/) ? "{#{item[1..-1]}}" : item
                    end.join('/'),          # => "/api/v1/examples/{id}"
              ctrl_action: infos[2]         # => "api/v1/examples#index"
          }
        end.group_by {|api| api[:ctrl_action].split('#').first } # => { "api/v1/examples" => [..] }, group by paths
      end
    end
  end
end
