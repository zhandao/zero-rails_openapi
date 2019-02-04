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

  def write_docs(if: true, read_on_controller: true)
    (docs = generate_docs(read_on_controller)) and Tip.loaded
    return unless binding.local_variable_get :if

    FileUtils.mkdir_p Config.file_output_path
    docs.each do |name, doc|
      File.write "#{Config.file_output_path}/#{name}.json", JSON.pretty_generate(doc)
      Tip.generated(name.to_s.rjust(docs.keys.map(&:size).max))
    end
  end

  def generate_docs(read_on_controller)
    return Tip.no_config if Config.docs.keys.blank?
    traverse_controllers if read_on_controller
    Dir[*Array(Config.doc_location)].each { |file| require file }
    Config.docs.keys.map { |name| [ name, generate_doc(name) ] }.to_h
  end

  def generate_doc(doc_name)
    settings, doc = init_hash(doc_name)
    [*(bdc = settings[:base_doc_classes]), *bdc.flat_map(&:descendants)].each do |kls|
      next if kls.oas[:doc].blank?
      doc[:paths].merge!(kls.oas[:apis])
      doc[:tags] << kls.oas[:doc][:tag]
      doc[:components].deep_merge!(kls.oas[:doc][:components] || { })
      OpenApi.routes_index[kls.oas[:route_base]] = doc_name
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

  def traverse_controllers
    Dir['./app/controllers/**/*_controller.rb'].each do |file|
      file.sub('./app/controllers/', '').sub('.rb', '').camelize.constantize
    end
  end
end
