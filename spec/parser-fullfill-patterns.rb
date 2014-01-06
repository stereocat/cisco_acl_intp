# -*- coding: utf-8 -*-
require 'yaml'
require 'erb'

# data files
TOKEN_SEQ_FILE_LIST = [
  'acldata-stdacl-token-seq.yml',
  'acldata-extacl-token-seq.yml',
  # 'acldata-extacl-objgrp-token-seq.yml'
]

# return spec conf dir
def _spec_conf_dir(file)
  specdir = Dir.new('./spec/conf/')
  File.join(specdir.path, file)
end

# return spec data dir
def _spec_data_dir(file)
  datadir = Dir.new('./spec/data/')
  File.join(datadir.path, file)
end

def gen_testcase(tokens, fields)
  if fields.empty?
    [{ data: '', msg: '', valid: true }]
  else
    field = fields.shift
    field_patterns = tokens[field.intern]
    # generate testpatterns recursively.
    leftover_results = gen_testcase(tokens, fields)
    create_data(field_patterns, leftover_results)
  end
end

def create_data(field_patterns, leftover_results)
  field_patterns.reduce([]) do |curr_results, each|
    leftover_results.each do |each_res|
      ## do not add pattern that has multiple 'false'
      ## add single fault pattern.
      curr_results.push(single_data(each, each_res)) if each_res[:valid]
    end
    curr_results
  end
end

def single_data(curr, leftover)
  {
    data: [curr[:data], leftover[:data]].join(' '),
    msg: curr[:msg], # used only single fault case
    valid: curr[:valid] # used only single fault case
  }
end

def each_test
  TOKEN_SEQ_FILE_LIST.each do |each_file|
    token_seq_data = YAML.load_file(_spec_conf_dir(each_file))
    token_seq_data.each do |each|
      puts "Test Name: #{each[:testname]}"
      puts "Test Case File: #{each[:casedata]}"
      yield(each)
    end
  end
end

##############################
# generate test case data file

puts '## generate test case data file'
each_test do |each|
  # read tokens pattern data
  tokens = YAML.load_file(_spec_conf_dir(each[:casedata]))
  # generate test case data
  testcase_list = gen_testcase(tokens, each[:fieldseq])

  # write datafile
  case_file_base = [each[:testname], '.yml'].join
  puts "Test Case Data: #{case_file_base}"
  case_file = _spec_data_dir(case_file_base)
  File.open(case_file, 'w') do |file|
    file.puts YAML.dump(testcase_list.flatten)
  end
end

##############################
# run test per test case file

code_data = DATA.read
puts '## generate spec code'
each_test do |each|
  spec_file_base = each[:testname] + '_spec.rb'
  puts "Spec code Data: #{spec_file_base}"
  File.open(_spec_data_dir(spec_file_base), 'w') do |file|
    code_erb = ERB.new(code_data, nil, '-')
    file.puts code_erb.result(binding)
  end
end

__END__
# -*- coding: utf-8 -*-
require 'spec_helper'
require 'stringio'

describe 'Parser' do
  describe '#parse_file' do
    before do
      @parser = CiscoAclIntp::Parser.new(color: false)
    end

<%-
  tests = YAML.load_file(_spec_data_dir(each[:testname] + '.yml'))
  test_total = tests.length
  test_curr = 1

  tests.each do |t|
    now = sprintf(
      "%d/%.1f\%", test_curr, (100.0 * test_curr / test_total)
    )
    if t[:valid]
-%>
    it 'should be parsed acl [<%= now %>]: <%= t[:data] %>' do
      datastr = StringIO.new('<%= t[:data] %>', 'r')
      @parser.parse_file(datastr)
      @parser.contains_error?.should be_false
    end
<%-
    else
-%>
    it 'should not be parsed acl [<%= now %>]: <%= t[:data] %>' do
      datastr = StringIO.new('<%= t[:data] %>', 'r')
      @parser.parse_file(datastr)
      @parser.contains_error?.should be_true
    end
<%-
    end
    test_curr = test_curr + 1
  end
-%>
  end # describe parse_file
end # describe Parser
