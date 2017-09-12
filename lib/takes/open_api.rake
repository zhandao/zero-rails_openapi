namespace :zero do
  desc 'Generate OpenApi documentation files'
  task :api => [:environment] do |t, args|
    ZeroRails::OpenApi.write_docs
  end
end