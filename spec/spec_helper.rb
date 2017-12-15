require 'bundler/setup'
require 'pp'
require 'open_api'
require 'support/api_doc'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec::Matchers.define :have_keys do |*expected|
  match do |actual|
    expected_have_keys?(actual, expected)
  end

  def expected_have_keys?(actual, expected)
    expected.each do |exp|
      if exp.is_a?(Hash)
        exp_key = exp.keys.first
        break false if actual[exp_key].nil? || !expected_have_keys?(actual[exp_key], exp.values.first)
      else
        break false if actual[exp].nil?
      end
    end
  end
end

def correct(&block)
  context 'when it is called correctly', &block
end

def config(&block)
  OpenApi::Config.tap { |it| it.instance_eval(&block) }
end

def before_config(&block)
  before { config(&block) }
end
