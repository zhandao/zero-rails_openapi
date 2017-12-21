require 'support/open_api'
require 'support/goods_doc'
require 'support/application_record'

# action when `before`
def before_do(&block)
  before { GoodsDoc.class_eval(&block) }
end

def before_do!(&block)
  before_do(&block)
  before { OpenApi.write_docs generate_files: false }
end

module Temp; cattr_accessor :stru, :expect_it, :expect_path; end

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

# put DSL block into the specified method(setting by default_in) when `it`
def it_dsl!(&block)
  GoodsDoc.class_exec(*default_in) { |method, *args| send(method, *args, &block) }
  OpenApi.write_docs generate_files: false
end

def its_structure(val = nil)
  Temp.stru = val if val
  Temp.stru.clone
end

def desc(object, key: nil, stru: nil, group: :describe, &block)
  its_structure(stru)

  send group, group == :describe ? "##{object}" : object do
    let(:doc) do
      val = OpenApi.docs[:zro]&.deep_symbolize_keys
      if key_path
        key_path.map { |p| val = val[p] }.last
      else
        val[default_in.first]
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

def ctx(desc, key: nil, stru: nil, &block)
  desc(desc, key: key, stru: stru, group: :context, &block)
end

def mk dsl_block, desc = nil, it: nil, eq: nil, have_keys: nil, doc_will_has_keys: nil, **other
  alias_of_have_keys = %i[ have_key have_key! have_keys! all_have_keys all_have_keys! will_have_keys will_have_keys! ]
  _have_keys = other.values_at(*alias_of_have_keys).compact.first
  it_blk = ->(excepted) { is_expected.to eq excepted  } if (eq ||= other[:will_eq])
  it_blk = ->(excepted) { is_expected.to have_keys excepted  } if (have_keys ||= _have_keys)
  it_blk = ->(excepted) { expect(doc).to have_keys excepted  } if doc_will_has_keys
  excepted = doc_will_has_keys || have_keys || eq

  sbj = nil
  it desc do
    it_dsl!(&dsl_block)
    sbj = subject
    excepted ? instance_exec(excepted, &it_blk) : instance_eval(&it)
  end

  return if (t = other.values_at(*alias_of_have_keys.grep(/!/)).compact.first).blank?
  (t.try(:keys) || Array(t)).each do |key|
    let(key.to_s.underscore) { Temp.expect_it = key.to_s.underscore; sbj[key] }
  end
end

def then_it(desc = nil, &block)
  { it: block, desc: desc }
end

alias _it then_it

def focus_on(key, *path)
  example "---> focus on: #{key}#{path.map { |p| '[:'+ p.to_s + ']' }.join}" do
    send(key.to_s.underscore)
    Temp.expect_path = path
    expect(true).to be_truthy
  end
end

def expect_it(*args, eq: nil, have_keys: nil, &block)
  desc, key = args.size == 2 ? args : [args.first, nil]
  block = ->(excepted) { eq excepted } if eq
  block = ->(excepted) { have_keys excepted } if have_keys
  it_block = ->(obj, expectation, excepted) { expect(obj).to instance_exec(excepted, &expectation) }
  excepted = have_keys || eq

  it desc do
    obj = send(Temp.expect_it)
    Temp.expect_path.each { |p| obj = obj[p] }
    obj = key ? obj[key] : obj
    instance_exec(obj, block, excepted, &it_block)
  end
end

def expect_its(key, desc = nil, **e,&block)
  expect_it(desc, key, **e, &block)
end
