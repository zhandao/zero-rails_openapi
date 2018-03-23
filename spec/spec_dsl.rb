require 'support/open_api'
require 'support/goods_doc'
require 'support/application_record'

# e.g. `get_and_dig_doc 'info'` will make `doc()` to be `OpenApi.docs[:zro]['info']`.
def get_and_dig_doc key_path = nil
  let(:doc) do
    doc = OpenApi.docs[:zro]&.deep_symbolize_keys
    key_path ? doc.dig(*key_path) : doc
  end
end

alias set_doc get_and_dig_doc

# Execute block inside class GoodsDoc.
def _do(block)
  GoodsDoc.class_exec(&block)
end

# Put DSL block into the specified method (setting by dsl_in()).
def _dsl(block)
  GoodsDoc.class_exec(*dsl_in) { |method, *args| send(method, *args, &block) }
end

def _write_docs
  OpenApi.write_docs(generate_files: false)
  GoodsDoc.class_eval { undo_dry; @api_info = { } }
end

def _do!(block)
  _do(block); _write_docs
end

def _dsl!(block)
  _dsl(block); _write_docs
end

# Execute block inside class GoodsDoc when rspec `before`.
def before_do(&block); before { _do(block) } end

def after_do(&block); after { _do(block) } end

def before_do!(&block); before { _do!(block) } end

# Put DSL block into the specified method when rspec `before`. For example:
# we declared `let(:dsl_in) { [:api, :action, 'test'] }`,
# then we call `before_dsl { query :name, String }`,
# it is the same effect as:
#   before_do {
#     api :action_name, 'test api' do
#       query :name, String
#     end
#   }
def before_dsl!(&block); before { _dsl!(block) } end

module Temp
  cattr_accessor :structure, :expect_it, :expect_key, :expect_path
end

def set_structure(val); Temp.structure = val end
def its_structure;      Temp.structure.clone end

def has_its_structure;  { has_keys: its_structure } end
def has_its_structure!; { has_keys!: its_structure } end

alias all_have_its_structure has_its_structure

# method `desc()` and `ctx()` will re-define the `subject` by using given params. For example:
#   desc :method_name, subject: :schema
# will do something like:
#   let(:schema) { doc[:schema] }
#   subject { schema }
#
# group: :describe or :context
# stru: subject's hash structure.
#   Notice the `subject` is re-defined in the current group.
def desc(object, subject: nil, stru: nil, group: :describe, &block)
  subject_key = binding.local_variable_get(:subject)
  set_structure(stru)

  send group, group_description = (group == :describe ? "##{object}" : object) do
    if subject_key
      let(subject_key) { doc&.[](subject_key) }
      subject { send(subject_key) }
    else
      subject { doc }
    end

    instance_eval(&block)
  end
end

def ctx(desc, **args, &block)
  desc(desc, group: :context, **args, &block)
end

# Just a customized rspec it() assertion func.
# Basically, mk() execute _dsl!(dsl_block) inside rspec it { },
#   then run assertion matchers (which is passed to mk() through k-v params like `get`) ON the **subject**.
# The k-v params are all the mapping of rspec matchers:
#   get, will_get, be -> eq | has_keys -> have_key | has_size -> have_size | include -> include |
#   raise -> raise_error
# Usage like: mk -> { query :id, Integer }, include: { name: 'id' } # when subject is parameter[0] it will pass.
# The key 'it' allows to pass a expectation block, like: mk -> { nil }, it: { be_nil }
#
# Extension, mk() has other 2 functions (maybe it needs refactoring).
# One is about when param key like `has_keys!` is used, one is about when param key `take` is used.
# You can read the following comments for knowing more.
def mk dsl_block, desc0 = nil, desc: nil, scope: :_dsl!, get: nil, has_keys: nil, has_size: nil,
       doc_will_has_keys: nil, include: nil, raise: nil, it: nil, take: nil, **other
  assertions = [ ]

  expected_value = [get, other[:will_get], other[:be]].compact.first
  assertions << -> { is_expected.to eq expected_value } unless expected_value.nil?

  aliases_of_have_keys = %i[ have_key have_key! have_keys have_keys! all_have_keys all_have_keys!
                             has_key  has_key!  has_keys! will_have_keys will_have_keys! ]
  specified_keys ||= has_keys || other.values_at(*aliases_of_have_keys).compact.first
  assertions << -> { is_expected.to have_keys specified_keys } if specified_keys

  size = has_size || other[:has_size!]
  assertions << -> { is_expected.to have_size size } if size

  assertions << -> { is_expected.to include include } if include
  assertions << -> { expect { subject }.to raise_error *Array(raise) } if raise
  assertions << -> { expect(doc).to have_keys doc_will_has_keys } if doc_will_has_keys

  assertion_blk = it
  desc ||= '---> after specified dsl' if assertions.size.zero? && assertion_blk.nil?
  sbj = nil
  it desc0 || desc do
    send(scope, dsl_block) # call to _dsl! (default) or _do!
    assertions.each { |assertion| instance_exec(&assertion) }
    is_expected.to instance_exec(&assertion_blk) if assertion_blk
    sbj = subject rescue nil
  end

  # when using the bang key to declare `have_key` assertion (like `has_keys!`),
  #   the expected keys will be used to define `let` and value will be `subject[key]`.
  # e.g. `has_key!: [:a]`, will make: `let(:a) { subject[:a] }`
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

# Just like mk(), but it will execute _do!(dsl_block) but not _dsl!.
def make dsl_block, desc0 = nil, **args
  mk dsl_block, desc0, scope: :_do!, **args
end

# Allows you to write like: mk -> { nil}, then_it { be_nil }
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
  end
end

# focus on inside focus_obj
def step_into(*path, desc: nil)
  focus_on Temp.expect_key, *path, desc: desc, mode: :step_into
end

# Do something like: it { expect(focus_obj).to .. }
#
# Example: suppose a() returns { b: { c: 123 } }
# focus_on :a, :b
#   then: Temp.expect_key == :a, Temp.expect_it == 'a', Temp.expect_path == [:b]
# expect_it eq: { c: 123 }
#   will pass, just like: it { expect(a[:b]).to eq c: 123 }
# expect_its :c, eq: 123
#   will pass, just like: it { expect(a[:b][:c]).to eq 123 }
#
# step_into :c
# expect_it eq: 123
#   will pass
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
