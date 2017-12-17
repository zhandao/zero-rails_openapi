require 'simplecov'
SimpleCov.start

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
    expected.flatten! if expected.is_a?(Array)
    expected_have_keys?(actual, expected)
  end

  failure_message do |actual|
    expected.flatten! if expected.is_a?(Array)
    " expected: #{actual}\nhave keys: #{expected}"
  end

  def expected_have_keys?(actual, expected)
    actual = actual.is_a?(Array) ? actual : [actual]
    actual.map do |act|
      expected.each do |exp|
        if exp.is_a?(Hash)
          exp_key = exp.keys.first
          break false if act[exp_key].nil? || !expected_have_keys?(act[exp_key], exp.values.first)
        else
          break false if act[exp].nil?
        end
      end
    end.all?(&:present?)
  end
end

def correct(&block)
  context 'when it is called correctly', &block
end

def normally(&block)
  context 'when it is called normally', &block
end

def wrong(addition_desc = '', &block)
  context "when it is called wrongly#{': ' << addition_desc if addition_desc.present?}", &block
end

def config(&block)
  OpenApi::Config.tap { |it| it.instance_eval(&block) }
end

def before_config(&block)
  before { config(&block) }
end
