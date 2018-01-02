require 'active_support/hash_with_indifferent_access'
require 'open_api/config'

module OpenApi
  module Generator
    extend self

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def generate_docs(doc_name = nil)
        pp '[ZRO] No documents have been configured!' and return if Config.docs.keys.blank?

        Dir['./app/controllers/**/*_controller.rb'].each do |file|
          # Do Not `require`!
          #   It causes problems, such as making `skip_before_action` not working.
          # :nocov:
          file.sub('./app/controllers/', '').sub('.rb', '').camelize.constantize
          # :nocov:
        end
        Dir[*Array(Config.doc_location)].each { |file| require file }
        (doc_name || Config.docs.keys).map { |name| { name => generate_doc(name) } }.reduce({ }, :merge!)
      end

      def generate_doc(doc_name)
        settings = Config.docs[doc_name]
        doc = { openapi: '3.0.0', **settings.slice(:info, :servers) }.merge!(
                security: settings[:global_security], tags: [ ], paths: { },
                components: {
                    securitySchemes: { }, schemas: { }, parameters: { }, requestBodies: { }
                }.merge!(settings[:components] || { })
              )

        settings[:base_doc_class].descendants.each do |ctrl|
          doc_info = ctrl.instance_variable_get('@doc_info')
          next if doc_info.nil?

          doc[:paths].merge!(ctrl.instance_variable_get('@api_info') || { })
          doc[:tags] << doc_info[:tag]
          doc[:components].deep_merge!(doc_info[:components] || { })
          OpenApi.routes_index[ctrl.instance_variable_get('@route_base')] = doc_name
        end

        doc[:components].delete_if { |_, v| v.blank? }
        doc[:tags]  = doc[:tags].sort { |a, b| a[:name] <=> b[:name] }
        doc[:paths] = doc[:paths].sort.to_h

        OpenApi.docs[doc_name] = HashWithIndifferentAccess.new(doc.delete_if { |_, v| v.blank? })
      end

      def write_docs(generate_files: true)
        docs = generate_docs
        return unless generate_files
        # :nocov:
        output_path = Config.file_output_path
        FileUtils.mkdir_p output_path
        max_length = docs.keys.map(&:size).sort.last
        docs.each do |doc_name, doc|
          puts "[ZRO] `#{doc_name.to_s.rjust(max_length)}.json` has been generated."
          File.open("#{output_path}/#{doc_name}.json", 'w') { |file| file.write JSON.pretty_generate doc }
        end
        # :nocov:
      end
    end # end of module

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
            inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, nil)
            # :nocov:
          end
    end

    def routes_list
      @routes_list ||= routes.split("\n").drop(1).map do |line|
        next unless line.match?('#')
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
      routes_list[route_base]&.map do |action_info|
        action_info[:action_path].split('#').last
      end
    end

    def find_path_httpverb_by(route_base, action)
      routes_list[route_base]&.map do |action_info|
        if action_info[:action_path].split('#').last == action.to_s
          return [ action_info[:path], action_info[:http_verb].split('|').first ]
        end
      end
      nil
    end
  end
end
