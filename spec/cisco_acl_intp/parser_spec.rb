# -*- coding: utf-8 -*-
require 'spec_helper'
require 'yaml'

describe 'Parser' do
  describe '#parse_file' do
    before do
      @parser = CiscoAclIntp::Parser.new(color: false)
    end

    # test data file
    data_files = [
      'extended_acl.yml',
      # 'object_group.yml'
    ]

    data_files.each do |each_file|
      tests = YAML.load_file(_spec_conf_dir(each_file))
      # puts YAML.dump data

      tests.each do |each_test|
        # filename
        acl_file_base = [each_test[:symbol], '.acl.yml'].join
        acl_file = _spec_data_dir(acl_file_base)

        # write acl to file
        File.open(acl_file, 'w') do |file|
          file.puts each_test[:acl]
        end

        if each_test[:correct]
          it "should be parsed #{acl_file} with no error" do
            @parser.parse_file(acl_file)
            @parser.contains_error?.should be_false
          end
        else
          it "should be parsed #{acl_file} with error" do
            @parser.parse_file(acl_file)
            @parser.contains_error?.should be_true
          end
        end
      end

    end

  end # parse_file
end # Parser

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
