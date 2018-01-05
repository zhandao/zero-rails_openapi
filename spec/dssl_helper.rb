require 'support/open_api'
require 'support/goods_doc'
require 'support/application_record'

module Temp; cattr_accessor :stru, :expect_it, :expect_key, :expect_path; end

# action when `before`
def before_do(&block)
  before { GoodsDoc.class_eval(&block) }
end

def after_do(&block)
  after { GoodsDoc.class_eval(&block) }
end

# `*do!` and `*dsl!` bang methods will do `OpenApi.write_docs` at the end of each.
def before_do!(&block)
  before_do(&block)
  before { OpenApi.write_docs generate_files: false }
end

# put DSL block into the specified method(setting by dsl_in) when `before`
#   e.g. `let(:dsl_in) { [:api, :action, 'test'] }` declared,
#   then we call `before_dsl { query :name, String }`,
#   it is the same as: `before_do { api :action, 'test' { query :name, String } }`
def before_dsl(&block)
  before { GoodsDoc.class_exec(*dsl_in) { |method, *args| send(method, *args, &block) } }
end

alias dsl before_dsl

def before_dsl!(&block)
  before_dsl(&block)
  before { OpenApi.write_docs generate_files: false }
end

alias dsl! before_dsl!

# action when `it`
def it_do!(&block)
  GoodsDoc.class_exec(&block)
  OpenApi.write_docs generate_files: false
  GoodsDoc.class_eval { undo_dry; @api_info = { } }
end

# put DSL block into the specified method(setting by dsl_in) when `it`
def it_dsl!(&block)
  GoodsDoc.class_exec(*dsl_in) { |method, *args| send(method, *args, &block) }
  OpenApi.write_docs generate_files: false
  GoodsDoc.class_eval { undo_dry; @api_info = { } }
end

def get_and_dig_doc key_path = nil
  let(:doc) do
    doc = OpenApi.docs[:zro]&.deep_symbolize_keys
    key_path ? doc.dig(*key_path) : doc
  end
end

alias set_doc get_and_dig_doc

# method `desc` and `ctx` will define `subject` by given info. e.g.
#   `desc :method_name, subject: :schema do .. end`
#   makes: `let(:schema) { doc[:schema] }` and `subject { schema }`
def desc(object, subject: nil, stru: nil, group: :describe, &block)
  subject_key = binding.local_variable_get(:subject)
  its_structure(stru)

  send group, (group == :describe ? "##{object}" : object) do # `describe` or `context`
    if subject_key
      let(subject_key.to_s.underscore) { doc&.[](subject_key) }
      subject { send(subject_key.to_s.underscore) }
    else
      subject { doc }
    end

    instance_eval(&block)
  end
end

def ctx(desc, **args, &block)
  desc(desc, group: :context, **args, &block)
end

def mk dsl_block, desc0 = nil, desc: nil, scope: :it_dsl!, eq: nil, has_keys: nil, has_size: nil, take: nil,
       doc_will_has_keys: nil, include: nil, raise: nil, it: nil, **other
  aliases_of_have_keys = %i[ have_key have_key! have_keys have_keys! all_have_keys all_have_keys!
                             has_key  has_key!  has_keys! will_have_keys will_have_keys! ]
  keys ||= has_keys || other.values_at(*aliases_of_have_keys).compact.first
  size = has_size || other[:has_size!]
  assertion_blk = it
  expected_value = [eq, other[:will_eq], other[:be]].compact.first

  assertions = [ ]
  assertions << -> { is_expected.to eq expected_value } unless expected_value.nil?
  assertions << -> { is_expected.to have_keys keys } if keys
  assertions << -> { is_expected.to include include } if include
  assertions << -> { expect(doc).to have_keys doc_will_has_keys } if doc_will_has_keys
  assertions << -> { expect(subject).to have_size size } if size
  assertions << -> { expect { subject }.to raise_error *Array(raise) } if raise

  desc ||= '---> after specified dsl' if assertions.size.zero? && assertion_blk.nil?
  sbj = nil
  it desc0 || desc do
    send(scope, &dsl_block) # exec `it_dsl!` or `it_do!`
    assertions.each { |assertion| instance_exec(&assertion) }
    is_expected.to instance_exec(&assertion_blk) if assertion_blk
    sbj = subject rescue nil
  end

  # when using the bang key to declare `have_keys` assertion (like `has_keys!`),
  #   the expected keys will be used to define `let`s that value is `subject[key]`.
  # e.g. `has_key!: [:a]`, makes: `let(:a) { subject[:a] }`
  if (expected = other.values_at(*aliases_of_have_keys.grep(/!/)).compact.first).present?
    (expected.try(:keys) || Array(expected)).each do |key|
      let(key.to_s.underscore) { sbj[key] }
    end
  end

  # Similar to the above. e.g.
  #   `take: 1`, makes: `let(:item_1) { subject[1] }`
  #   `has_size!: 2`, makes: `let(:item_0) { subject[0] }`, `let(:item_1) { subject[1] }`
  if (take || other[:has_size!]).present?
    Array(take ? take : 0..other[:has_size!]-1).each do |i|
      let("item_#{i}") { sbj[i] }
    end
  end
end

alias api mk

def make dsl_block, desc0 = nil, **args
  mk dsl_block, desc0, scope: :it_do!, **args
end

def then_it(desc = nil, &block)
  { it: block, desc: desc }
end

alias _it then_it

def its_structure(val = nil)
  Temp.stru = val if val
  Temp.stru.clone
end

def has_its_structure
  { has_keys: its_structure }
end

def has_its_structure!
  { has_keys!: its_structure }
end

alias all_have_its_structure has_its_structure

def focus_on(key, *path, desc: nil, mode: nil)
  Temp.expect_key = key
  example "---> focus on: #{key}#{path.map { |p| '[:'+ p.to_s + ']' }.join}#{', ' + desc if desc}" do
    Temp.expect_it = key.to_s.underscore
    path = Temp.expect_path + path if mode == :step_into
    Temp.expect_path = path
  end
end

# focus on inside focus_obj
def step_into(*path, desc: nil)
  focus_on Temp.expect_key, *path, desc: desc, mode: :step_into
end

# the same effect as: it { expect(focus_obj).to .. }
def expect_it(*args, eq: nil, have_keys: nil, has_keys: nil, has_key: nil, desc: nil, &block)
  desc0, key = args.size == 2 ? args : [args.first, nil]
  block = ->(excepted) { eq excepted } unless eq.nil?
  block = ->(excepted) { have_keys excepted } if (has_keys ||= have_keys || has_key)
  it_block = ->(obj, expectation, excepted) { expect(obj).to instance_exec(excepted, &expectation) }
  excepted = has_keys || eq

  _desc = "it's #{key} is expected to #{has_keys ? 'have keys' : 'eq'}: #{excepted.inspect}" if key && excepted
  it desc || desc0 || _desc do
    obj = send(Temp.expect_it)
    Temp.expect_path.each { |p| obj = obj[p] }
    obj = key ? obj[key] : obj
    instance_exec(obj, block, excepted, &it_block)
  end
end

def expect_its(key, desc = nil, **args, &block)
  expect_it(desc, key, **args, &block)
end
