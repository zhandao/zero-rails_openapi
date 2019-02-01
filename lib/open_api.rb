# frozen_string_literal: true

require 'colorize'

require 'open_api/version'
require 'open_api/support/tip'
require 'open_api/config'
require 'open_api/generator'
require 'open_api/dsl'

module OpenApi
  module_function
  cattr_accessor :routes_index, default: { }
  cattr_accessor :docs, default: { }

  def write_docs(args = { if: true })
    docs = generate_docs
    Tip.loaded if ENV['RAILS_ENV']
    return unless args[:if]

    FileUtils.mkdir_p Config.file_output_path
    docs.each do |name, doc|
      File.write "#{Config.file_output_path}/#{name}.json", JSON.pretty_generate(doc)
      Tip.generated(name.to_s.rjust(docs.keys.map(&:size).max))
    end
  end

  def generate_docs
    return Tip.no_config if Config.docs.keys.blank?

    # TODO
    # :nocov:
    Dir['./app/controllers/**/*_controller.rb'].each do |file|
      file.sub('./app/controllers/', '').sub('.rb', '').camelize.constantize
    end
    # :nocov:
    Dir[*Array(Config.doc_location)].each { |file| require file }
    Config.docs.keys.map { |name| [ name, generate_doc(name) ] }.to_h
  end

  def generate_doc(doc_name)
    settings, doc = init_hash(doc_name)
    [*(bdc = settings[:base_doc_classes]), *bdc.flat_map(&:descendants)].each do |ctrl|
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

    OpenApi.docs[doc_name] = doc#.delete_if { |_, v| v.blank? }
  end

  def init_hash(doc_name)
    settings = Config.docs[doc_name]
    doc = { openapi: '3.0.0', **settings.slice(:info, :servers) }.merge!(
        security: settings[:global_security], tags: [ ], paths: { },
        components: {
            securitySchemes: settings[:securitySchemes] || { },
            schemas: { }, parameters: { }, requestBodies: { }
        }
    )
    [ settings, doc ]
  end
end
