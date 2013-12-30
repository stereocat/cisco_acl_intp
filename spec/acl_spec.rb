# -*- coding: utf-8 -*-

require 'spec_helper'

include CiscoAclIntp
AclContainerBase.disable_color

describe NamedExtAcl do
  describe '#add_entry' do
    before do
      @acl = NamedExtAcl.new 'test-ext-acl'
    end

    it 'should be zero when initialized' do
      @acl.size.should be_zero
    end

    it 'should be size 1 and matches aclstr when added a acl entry' do
      ea = ExtendedAce.new(
        action: 'permit',
        protocol: 'udp',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255'
        }
      )
      @acl.add_entry ea
      @acl.size.should eq 1
      aclstr = <<'EOL'
ip access-list extended test-ext-acl
 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end
  end

  describe '#add_entry_by_params' do
    before do
      @acl = NamedExtAcl.new 'test-ext-acl2'
      @acl.add_entry_by_params(
        action: 'permit',
        protocol: 'udp',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255'
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        protocol: 'tcp',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.0'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255',
          operator: 'gt',
          port1: AceUdpProtoSpec.new(
            number: 32_768
          )
        }
      )
    end

    it 'should be size 2' do
      @acl.size.should eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
ip access-list extended test-ext-acl2
 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
 deny tcp host 192.168.3.3 192.168.4.0 0.0.0.255 gt 32768
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end

    it 'mutches aclstr with remark' do
      rmk = RemarkAce.new ' this is remark!!'
      @acl.add_entry rmk
      aclstr = <<'EOL'
ip access-list extended test-ext-acl2
 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
 deny tcp host 192.168.3.3 192.168.4.0 0.0.0.255 gt 32768
 remark this is remark!!
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end

  end

  describe '#search_ace' do
    # extended ace については named でも numbered でも同様なので
    # named ext ace についてだけテスト記載(numbered ext acl については省略)
    before do
      @acl = NamedExtAcl.new 'test-ext-acl2'
      @acl.add_entry_by_params(
        action: 'permit',
        protocol: 'udp',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255'
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        protocol: 'tcp',
        src: {
          ipaddr: '192.168.10.3',
          wildcard: '0.0.0.0'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255',
          operator: 'gt',
          port1: AceUdpProtoSpec.new(
            number: 32_768
          )
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        protocol: 'ip',
        src: {
          ipaddr: '0.0.0.0',
          wildcard: '255.255.255.255'
        },
        dst: {
          ipaddr: '10.0.0.0',
          wildcard: '0.0.0.255'
        }
      )
    end

    it 'should be match 2nd entry' do
      ace = @acl.search_ace(
        protocol: 'tcp',
        src_ip: '192.168.10.3',
        src_port: 64_332,
        dst_ip: '192.168.4.5',
        dst_port: 32_889
      )
      ace.to_s.should be_aclstr('deny tcp host 192.168.10.3 192.168.4.0 0.0.0.255 gt 32768')
    end

    it 'should be last entry' do
      ace = @acl.search_ace(
        protocol: 'udp',
        src_ip: '192.168.10.3',
        src_port: 64_332,
        dst_ip: '10.0.0.3',
        dst_port: 33_890
      )
      ace.to_s.should be_aclstr('deny ip any 10.0.0.0 0.0.0.255')
    end

    it 'should be nil if not found match entry' do
      @acl.search_ace(
        protocol: 'udp',
        src_ip: '192.168.10.3',
        src_port: 62_223,
        dst_ip: '11.0.0.3',
        dst_port: 33_333
      ).should be_nil
    end
  end
end

describe NumberedExtAcl do
  describe '#add_entry' do
    before do
      @acl = NumberedExtAcl.new 102
    end

    it 'should be zero when initialized' do
      @acl.size.should be_zero
    end

    it 'should be size 1 and matches aclstr when added a acl entry' do
      ea = ExtendedAce.new(
        action: 'permit',
        protocol: 'udp',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255'
        }
      )
      @acl.add_entry ea
      @acl.size.should eq 1
      aclstr = <<'EOL'
access-list 102 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end
  end

  describe '#add_entry_by_params' do
    before do
      @acl = NumberedExtAcl.new 104
      @acl.add_entry_by_params(
        action: 'permit',
        protocol: 'udp',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255'
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        protocol: 'tcp',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.0'
        },
        dst: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255',
          operator: 'gt',
          port1: AceUdpProtoSpec.new(
            number: 32_768
          )
        }
      )
    end

    it 'should be size 2' do
      @acl.size.should eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
access-list 104 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
access-list 104 deny tcp host 192.168.3.3 192.168.4.0 0.0.0.255 gt 32768
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end

    it 'mutches aclstr with remark' do
      rmk = RemarkAce.new ' this is remark!!'
      @acl.add_entry rmk
      aclstr = <<'EOL'
access-list 104 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
access-list 104 deny tcp host 192.168.3.3 192.168.4.0 0.0.0.255 gt 32768
access-list 104 remark this is remark!!
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end
  end
end

describe NamedStdAcl do
  describe '#add_entry' do
    before do
      @acl = NamedStdAcl.new 'test-std-acl'
    end

    it 'should be zero when initialized' do
      @acl.size.should be_zero
    end

    it 'should be size 1 and matches aclstr when added a acl entry' do
      sa = StandardAce.new(
        action: 'permit',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        }
      )
      @acl.add_entry sa
      @acl.size.should eq 1
      aclstr = <<'EOL'
ip access-list standard test-std-acl
 permit 192.168.3.0 0.0.0.127
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end
  end

  describe '#add_entry_by_params' do
    before do
      @acl = NamedStdAcl.new 'test-std-acl2'
      @acl.add_entry_by_params(
        action: 'permit',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        src: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255'
        }
      )
    end

    it 'should be size 2' do
      @acl.size.should eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
ip access-list standard test-std-acl2
 permit 192.168.3.0 0.0.0.127
 deny 192.168.4.0 0.0.0.255
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end

    it 'mutches aclstr with remark' do
      rmk = RemarkAce.new ' this is remark!!'
      @acl.add_entry rmk
      aclstr = <<'EOL'
ip access-list standard test-std-acl2
 permit 192.168.3.0 0.0.0.127
 deny 192.168.4.0 0.0.0.255
 remark this is remark!!
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end

  end

  describe '#search_ace' do
    # standard ace については named でも numbered でも同様なので
    # standard ext ace についてだけテスト記載(numbered std acl については省略)
    before do
      @acl = NamedStdAcl.new 'test-stdacl3'
      @acl.add_entry_by_params(
        action: 'permit',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        src: {
          ipaddr: '192.168.10.3',
          wildcard: '0.0.0.0'
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        src: {
          ipaddr: '10.0.0.0',
          wildcard: '0.0.0.255'
        }
      )
    end

    it 'should be match 2nd entry' do
      ace = @acl.search_ace(
        src_ip: '192.168.10.3',
        src_port: 64_332
      )
      ace.to_s.should be_aclstr('deny host 192.168.10.3')
    end

    it 'should be last entry' do
      ace = @acl.search_ace(
        src_ip: '10.0.0.3',
        src_port: 33_890
      )
      ace.to_s.should be_aclstr('deny 10.0.0.0 0.0.0.255')
    end

    it 'should be nil if not found match entry' do
      @acl.search_ace(
        protocol: 'udp',
        src_ip: '11.0.0.3',
        src_port: 33_333
      ).should be_nil
    end
  end

end

describe NumberedStdAcl do
  describe '#add_entry' do
    before do
      @acl = NumberedStdAcl.new 10
    end

    it 'should be zero when initialized' do
      @acl.size.should be_zero
    end

    it 'should be size 1 and matches aclstr when added a acl entry' do
      sa = StandardAce.new(
        action: 'permit',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        }
      )
      @acl.add_entry sa
      @acl.size.should eq 1
      aclstr = <<'EOL'
access-list 10 permit 192.168.3.0 0.0.0.127
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end
  end

  describe '#add_entry_by_params' do
    before do
      @acl = NumberedStdAcl.new 14
      @acl.add_entry_by_params(
        action: 'permit',
        src: {
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        src: {
          ipaddr: '192.168.4.4',
          wildcard: '0.0.0.255'
        }
      )
    end

    it 'should be size 2' do
      @acl.size.should eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
access-list 14 permit 192.168.3.0 0.0.0.127
access-list 14 deny 192.168.4.0 0.0.0.255
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end

    it 'mutches aclstr with remark' do
      rmk = RemarkAce.new ' this is remark!!'
      @acl.add_entry rmk
      aclstr = <<'EOL'
access-list 14 permit 192.168.3.0 0.0.0.127
access-list 14 deny 192.168.4.0 0.0.0.255
access-list 14 remark this is remark!!
EOL
      @acl.to_s.should be_aclstr(aclstr)
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
