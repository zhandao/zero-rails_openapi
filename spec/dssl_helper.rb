require 'support/open_api'
require 'support/goods_doc'
require 'support/application_record'

# action when `before`
def before_do(&block)
  before { GoodsDoc.class_eval(&block) }
end

def after_do(&block)
  after { GoodsDoc.class_eval(&block) }
end

def before_do!(&block)
  before_do(&block)
  before { OpenApi.write_docs generate_files: false }
end

module Temp; cattr_accessor :stru, :expect_it, :expect_key, :expect_path; end

# put DSL block into the specified method(setting by default_in) when `before`
def before_dsl(&block)
  before { GoodsDoc.class_exec(*default_in) { |method, *args| send(method, *args, &block) } }
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
  GoodsDoc.class_eval { undo_dry; @_api_infos = { } }
end

# put DSL block into the specified method(setting by default_in) when `it`
def it_dsl!(&block)
  GoodsDoc.class_exec(*default_in) { |method, *args| send(method, *args, &block) }
  OpenApi.write_docs generate_files: false
  GoodsDoc.class_eval { undo_dry; @_api_infos = { } }
end

def its_structure(val = nil)
  Temp.stru = val if val
  Temp.stru.clone
end

def should_be_its_structure
  { has_keys: its_structure }
end

def should_be_its_structure!
  { has_keys!: its_structure }
end

alias all_should_be_its_structure should_be_its_structure

def desc(object, subject: nil, stru: nil, group: :describe, &block)
  key = binding.local_variable_get(:subject)
  its_structure(stru)

  send group, group == :describe ? "##{object}" : object do
    let(:doc) do
      val = OpenApi.docs[:zro]&.deep_symbolize_keys
      if try(:subject_key_path)
        subject_key_path.map { |p| val = val[p] }.last
      elsif try(:default_in)
        val[default_in.first]
      else
        val
      end
    end

    if key
      let(key.to_s.underscore) { doc&.[](key) }
      subject { send(key.to_s.underscore) }
    else
      subject { doc }
    end

    instance_eval(&block)
  end
end

def ctx(desc, subject: nil, stru: nil, &block)
  desc(desc, subject: binding.local_variable_get(:subject), stru: stru, group: :context, &block)
end

def mk dsl_block, desc0 = nil, desc: nil, scope: :it_dsl!, it: nil, eq: nil, has_keys: nil, has_size: nil, take: nil,
       doc_will_has_keys: nil, raise: nil, **other
  alias_of_have_keys = %i[ have_key have_key! have_keys have_keys! all_have_keys all_have_keys!
                           has_key has_key! has_keys! will_have_keys will_have_keys! ]
  has_keys ||= other.values_at(*alias_of_have_keys).compact.first
  eq = [eq, other[:will_eq], other[:be]].compact.first

  it_blks = [ ]
  it_blks << [eq, ->(excepted) { is_expected.to eq excepted }] unless eq.nil?
  it_blks << [has_keys, ->(excepted) { is_expected.to have_keys excepted }] if has_keys
  it_blks << [doc_will_has_keys, ->(excepted) { expect(doc).to have_keys excepted }] if doc_will_has_keys
  it_blks << [has_size, ->(excepted) { expect(subject).to have_size excepted }] if (has_size ||= other[:has_size!])
  desc ||= '---> after specified dsl' if it_blks.size.zero? && it.nil?

  sbj = nil
  it desc0 || desc do
    send(scope, &dsl_block)
    it_blks.each do |(excepted, it_blk)|
      instance_exec(excepted, &it_blk)
    end
    is_expected.to instance_exec(&it) if it
    expect { subject }.to raise_error *Array(raise) if raise
    sbj = subject rescue nil
  end

  if (t = other.values_at(*alias_of_have_keys.grep(/!/)).compact.first).present?
    (t.try(:keys) || Array(t)).each do |key|
      let(key.to_s.underscore) { sbj[key] }
    end
  end

  if (take || size = other[:has_size!]).present?
    items = take ? Array(take) : (0..size-1).to_a
    items.each do |i|
      let("item_#{i}") { sbj[i] }
    end
  end
end

alias api mk

def make dsl_block, desc = nil, it: nil, eq: nil, has_keys: nil, doc_will_has_keys: nil, **other
  mk dsl_block, desc, scope: :it_do!, it: it, eq: eq, has_keys: has_keys, doc_will_has_keys: doc_will_has_keys, **other
end

def then_it(desc = nil, &block)
  { it: block, desc: desc }
end

alias _it then_it

def focus_on(key, *path, desc: nil, mode: nil)
  Temp.expect_key = key
  example "---> focus on: #{key}#{path.map { |p| '[:'+ p.to_s + ']' }.join}#{', ' + desc if desc}" do
    Temp.expect_it = key.to_s.underscore
    path = Temp.expect_path + path if mode == :step_into
    Temp.expect_path = path
    expect(true).to be_truthy
  end
end

def step_into(*path, desc: nil)
  focus_on Temp.expect_key, *path, desc: desc, mode: :step_into
end

def expect_it(*args, eq: nil, have_keys: nil, has_keys: nil, has_key: nil, desc: nil, &block)
  desc0, key = args.size == 2 ? args : [args.first, nil]
  block = ->(excepted) { eq excepted } unless eq.nil?
  block = ->(excepted) { have_keys excepted } if (has_keys ||= have_keys || has_key)
  it_block = ->(obj, expectation, excepted) { expect(obj).to instance_exec(excepted, &expectation) }
  excepted = has_keys || eq

  _desc = "it's #{key} should #{has_keys ? 'have keys' : 'eq'}: #{excepted.inspect}" if key && excepted
  it desc || desc0 || _desc do
    obj = send(Temp.expect_it)
    Temp.expect_path.each { |p| obj = obj[p] }
    obj = key ? obj[key] : obj
    instance_exec(obj, block, excepted, &it_block)
  end
end

def expect_its(key, desc = nil, **e,&block)
  expect_it(desc, key, **e, &block)
end
