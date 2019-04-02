# frozen_string_literal: true

module OpenApi
  module Router
    module_function

    def routes
      @routes ||=
          if (file = Config.rails_routes_file)
            File.read(file)
          else
            # :nocov:
            # ref https://github.com/rails/rails/blob/master/railties/lib/rails/tasks/routes.rake
            require './config/routes'
            all_routes = Rails.application.routes.routes
            require 'action_dispatch/routing/inspector'
            inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
            if Rails::VERSION::MAJOR < 6
              inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, nil)
            else
              inspector.format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new)
            end
            # :nocov:
          end
    end

    def routes_list
      @routes_list ||= routes.split("\n").drop(1).map do |line|
        next unless line['#']
        infos = line.match(/[A-Z|].*/).to_s.split(' ') # => [GET, /api/v1/examples/:id, api/v1/examples#index]

        {
            http_verb: infos[0].downcase, # => "get" / "get|post"
            path: infos[1][0..-11].split('/').map do |item|
                    item[':'] ? "{#{item[1..-1]}}" : item
                  end.join('/'),          # => "/api/v1/examples/{id}"
            action_path: infos[2]         # => "api/v1/examples#index"
        } rescue next
      end.compact.group_by { |api| api[:action_path].split('#').first } # => { "api/v1/examples" => [..] }, group by paths
    end

    def get_actions_by_route_base(route_base)
      routes_list[route_base]&.map { |action_info| action_info[:action_path].split('#').last }
    end

    def find_path_httpverb_by(route_base, action)
      routes_list[route_base]&.map do |action_info|
        if action_info[:action_path].split('#').last == action.to_s
          return [ action_info[:path], action_info[:http_verb].split('|').first ]
        end
      end ; nil
    end
  end
end
