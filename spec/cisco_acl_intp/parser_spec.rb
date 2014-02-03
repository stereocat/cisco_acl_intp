# -*- coding: utf-8 -*-

require 'spec_helper'
require 'yaml'

describe 'Parser' do
  describe '#parse_string' do
    before do
      @parser = CiscoAclIntp::Parser.new(color: false)
    end

    it 'should be parsed acl' do
      datastr = <<EOL
ip access-list extended FA8-OUT
 deny   udp any any eq bootpc
 deny   udp any any eq bootps
 permit tcp host 192.168.3.4 173.30.240.0 0.0.0.255 range 32768 65535
 deny udp 192.168.3.0 0.0.240.255 lt 1024 any eq 80
 remark network access-list remark!!
 permit tcp any any established
 deny tcp any any syn rst
 deny udp any any log-input hoge
 permit ip any any log
!
EOL
      @parser.parse_string(datastr)
      @parser.contains_error?.should be_false
    end

    it 'should not be parsed acl' do
      datastr = <<EOL
ip access-list extended FA8-OUT
 deny   udp any any eq bootpc
 deny   udp any any eq bootps
 remark !argment error! 65536
 permit tcp host 192.168.3.4 173.30.240.0 0.0.0.255 range 32768 65536
 remark !------cleared------!
 remark !argment error! 255 => 256
 deny udp 192.168.3.0 0.0.240.256 lt 1024 any eq 80
 remark !------cleared------!
 remark network access-list remark!!
 permit tcp any any established
 deny tcp any any syn rst
 remark !syntax error! tcp -> tp (typo)
 deny up any any log-input hoge
 remark !------cleared------!
 permit ip any any log
!
EOL
      @parser.parse_string(datastr)
      @parser.contains_error?.should be_true
    end
  end

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
