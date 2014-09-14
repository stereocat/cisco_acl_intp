# -*- coding: utf-8 -*-

require 'spec_helper'
require 'stringio'
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
!
EOL
      @parser.parse_string(datastr)
      expect(@parser.contains_error?).to be_falsey
      @parser.parse_string(StringIO.new(datastr))
      expect(@parser.contains_error?).to be_falsey
    end

    it 'should not be parsed acl' do
      datastr = <<EOL
ip access-list extended FA8-OUT
 remark !syntax error! tcp -> tp (typo)
 deny up any any log-input hoge
 remark !------cleared------!
 permit ip any any log
!
EOL
      @parser.parse_string(datastr)
      expect(@parser.contains_error?).to be_truthy
      @parser.parse_string(StringIO.new(datastr))
      expect(@parser.contains_error?).to be_truthy
    end

    it 'should be error by NON-IO object' do
      @parser.parse_string(123_456_789)
      expect(@parser.contains_error?).to be_truthy
      expect(@parser.error_list.shift).to match(/acl error/)
    end
  end

  describe '#parse_file with string' do
    before do
      @parser = CiscoAclIntp::Parser.new(color: false)
    end

    it 'should be parsed acl' do
      datastr = <<EOL
ip access-list extended FA8-OUT
 deny   udp any any eq bootpc
 deny   udp any any eq bootps
 permit tcp host 192.168.3.4 173.30.240.0 0.0.0.255 range 32768 65535
!
EOL
      @parser.parse_file(StringIO.new(datastr))
      expect(@parser.contains_error?).to be_falsey
    end

    it 'should not be parsed acl' do
      datastr = <<EOL
ip access-list extended FA8-OUT
 remark !syntax error! tcp -> tp (typo)
 deny up any any log-input hoge
 remark !------cleared------!
 permit ip any any log
!
EOL
      @parser.parse_file(StringIO.new(datastr))
      expect(@parser.contains_error?).to be_truthy
    end

    it 'should be error by NON-IO object' do
      @parser.parse_file(123_456_789)
      expect(@parser.contains_error?).to be_truthy
      expect(@parser.error_list.shift).to match(/Parse aborted/)
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
            expect(@parser.contains_error?).to be_falsey
          end
        else
          it "should be parsed #{acl_file} with error" do
            @parser.parse_file(acl_file)
            expect(@parser.contains_error?).to be_truthy
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
