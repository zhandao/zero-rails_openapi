namespace :openapi do
  desc 'Generate OpenApi documentation files'
  task :api => [:environment] do |t, args|
    OpenApi.write_docs
  end
end