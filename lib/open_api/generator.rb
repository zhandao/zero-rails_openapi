require 'open_api/config'

module OpenApi
  module Generator
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def generate_docs(doc_name = nil)
        Dir['./app/controllers/**/*_controller.rb'].each do |file|
          # Do Not `require`!
          #   It causes problems, such as making `skip_before_action` not working.
          file.sub('./app/controllers/', '').sub('.rb', '').camelize.constantize
        end
        # TODO: _doc should be configured
        Dir['./app/**/*_doc.rb'].each { |file| require file }
        if doc_name.present?
          [{ doc_name => generate_doc(doc_name) }]
        else
          Config.docs.keys.map { |api_key| { api_key => generate_doc(api_key) } }.reduce({ }, :merge)
        end
      end

      def generate_doc(doc_name)
        settings = Config.docs[doc_name]
        doc = { openapi: '3.0.0' }.merge(settings.slice :info, :servers).merge(
                security: settings[:global_security], tags: [ ], paths: { },
                components: {
                    securitySchemes: settings[:security_schemes] || { },
                    schemas: { }, parameters: { }, requestBodies: { }
                }
              )

        settings[:root_controller].descendants.each do |ctrl|
          ctrl_infos = ctrl.instance_variable_get('@_ctrl_infos')
          next if ctrl_infos.nil?
          doc[:paths].merge! ctrl.instance_variable_get('@_api_infos') || { }
          doc[:tags] << ctrl_infos[:tag]
          doc[:components].merge! ctrl_infos[:components] || { }
          OpenApi.paths_index[ctrl.instance_variable_get('@_ctrl_path')] = doc_name
        end
        doc[:components].delete_if { |_, v| v.blank? }
        doc[:tags]  = doc[:tags].sort { |a, b| a[:name] <=> b[:name] }
        doc[:paths] = doc[:paths].sort.to_h

        OpenApi.docs[doc_name] ||= ActiveSupport::HashWithIndifferentAccess.new(doc.delete_if { |_, v| v.blank? })
      end

      def write_docs(generate_files: true)
        docs = generate_docs
        return unless generate_files
        output_path = Config.file_output_path
        FileUtils.mkdir_p output_path
        max_length = docs.keys.map(&:size).sort.last
        # puts '[ZRO] * * * * * *'
        docs.each do |doc_name, doc|
          puts "[ZRO] `#{doc_name.to_s.rjust(max_length)}.json` has been generated."
          File.open("#{output_path}/#{doc_name}.json", 'w') { |file| file.write JSON.pretty_generate doc }
        end
      end
    end

    def self.routes_list
      routes =
        if (f = Config.rails_routes_file)
          File.read(f)
        else
          # ref https://github.com/rails/rails/blob/master/railties/lib/rails/tasks/routes.rake
          require './config/routes'
          all_routes = Rails.application.routes.routes
          require 'action_dispatch/routing/inspector'
          inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
          inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, nil)
        end

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

    def self.get_actions_by_ctrl_path(ctrl_path)
      routes_list[ctrl_path]&.map do |action_info|
        action_info[:action_path].split('#').last
      end
    end

    def self.find_path_httpverb_by(ctrl_path, action)
      routes_list[ctrl_path]&.map do |action_info|
        if action_info[:action_path].split('#').last == action.to_s
          return [ action_info[:path], action_info[:http_verb].split('|').first ]
        end
      end
      nil
    end
  end
end
