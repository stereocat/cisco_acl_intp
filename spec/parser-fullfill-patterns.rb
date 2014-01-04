# -*- coding: utf-8 -*-
require 'spec_helper'
require 'yaml'
require 'stringio'

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
      curr_results.push(single_data(each, each_res))
    end
    curr_results
  end
end

def single_data(curr, leftover)
  {
    data: create_datastr(curr, leftover),
    msg: create_message(curr, leftover),
    valid: create_valid(curr, leftover)
  }
end

def create_datastr(curr, leftover)
  [curr[:data], leftover[:data]].join(' ')
end

def create_message(curr, leftover)
  if curr[:msg]
    curr[:msg]
  else
    leftover[:msg] ? leftover[:msg] : ''
  end
end

def create_valid(curr, leftover)
  curr[:valid] && leftover[:valid]
end

##############################

token_seq_file_list = [
  'acldata-stdacl-token-seq.yml',
  'acldata-extacl-token-seq.yml',
  # 'acldata-extacl-objgrp-token-seq.yml'
]

testcase_list = []
token_seq_file_list.each do |each_token_seq_file|
  token_seq_data = YAML.load_file(_spec_dir(each_token_seq_file))
  token_seq_data.each do |each|
    # puts "Test Name: #{each[:testname]}"
    # puts "Test Case File: #{each[:casedata]}"
    tokens = YAML.load_file(_spec_dir(each[:casedata]))
    testcase_list.push gen_testcase(tokens, each[:fieldseq])
  end
end
# puts YAML.dump(testcase_list.flatten)

describe 'Parser' do
  describe '#parse_file' do
    before do
      @parser = CiscoAclIntp::Parser.new(color: false)
    end

    tlist = testcase_list.flatten
    test_total = tlist.length
    test_curr = 1
    tlist.each do |each|
      now = sprintf(
        "%d/%.1f\%", test_curr, (100.0 * test_curr / test_total)
      )
      print "Generating: #{now}\r"
      datastr = StringIO.new(each[:data], 'r')
      if each[:valid]
        it "should be parsed acl [#{now}]: #{each[:data]}" do
          @parser.parse_file(datastr)
          @parser.contains_error?.should be_false
        end
      else
        it "should not be parsed acl [#{now}]: #{each[:data]}" do
          @parser.parse_file(datastr)
          @parser.contains_error?.should be_true
        end
      end
      test_curr = test_curr + 1
    end
  end # describe parse_file
end # describe Parser
