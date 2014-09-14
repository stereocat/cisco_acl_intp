# -*- coding: utf-8 -*-
require 'spec_helper'

describe NamedExtAcl do
  describe '#add_entry' do
    before(:all) do
      @acl = NamedExtAcl.new 'test-ext-acl'
    end

    it 'should be zero when initialized' do
      expect(@acl.size).to be_zero
      expect(@acl.named_acl?).to be_truthy
      expect(@acl.numbered_acl?).to be_falsey
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
      expect(@acl.size).to eq 1
      aclstr = <<'EOL'
ip access-list extended test-ext-acl
 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
    end
  end

  describe '#add_entry_by_params' do
    before(:all) do
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
          port: AceUdpProtoSpec.new(32_768)
        }
      )
    end

    it 'should be size 2' do
      expect(@acl.size).to eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
ip access-list extended test-ext-acl2
 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
 deny tcp host 192.168.3.3 192.168.4.0 0.0.0.255 gt 32768
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
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
      expect(@acl.to_s).to be_aclstr(aclstr)
    end

  end

  describe '#find_aces_contains' do
    # for extended ace, it is same as named/numbered ace.
    # so that, tests only named-extended-ace
    # and omit numbered-extended-acl
    before(:all) do
      @acl = NamedExtAcl.new 'test-ext-acl2'
      @acl.add_entry_by_params(
        action: 'permit',
        protocol: 'udp',
        src: { ipaddr: '192.168.3.3', wildcard: '0.0.0.127' },
        dst: { ipaddr: '192.168.4.4', wildcard: '0.0.0.255' }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        protocol: 'tcp',
        src: { ipaddr: '192.168.10.3', wildcard: '0.0.0.0' },
        dst: {
          ipaddr: '192.168.4.4', wildcard: '0.0.0.255', operator: 'gt',
          port: AceUdpProtoSpec.new(32_768)
        }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        protocol: 'ip',
        src: { ipaddr: '0.0.0.0', wildcard: '255.255.255.255' },
        dst: { ipaddr: '10.0.0.0', wildcard: '0.0.0.255' }
      )
    end

    it 'should be match 2nd entry' do
      ace = @acl.find_aces_contains(
        protocol: 'tcp',
        src_operator: :eq, src_ip: '192.168.10.3', src_port: 64_332,
        dst_operator: :eq, dst_ip: '192.168.4.5',  dst_port: 32_889
      )
      expect(ace.to_s).to be_aclstr(
        'deny tcp host 192.168.10.3 192.168.4.0 0.0.0.255 gt 32768'
      )
    end

    it 'should be last entry' do
      ace = @acl.find_aces_contains(
        protocol: 'udp',
        src_operator: :eq, src_ip: '192.168.10.3', src_port: 64_332,
        dst_operator: :eq, dst_ip: '10.0.0.3',     dst_port: 33_890
      )
      expect(ace.to_s).to be_aclstr('deny ip any 10.0.0.0 0.0.0.255')
    end

    it 'should be nil if not found match entry' do
      expect(@acl.find_aces_contains(
        protocol: 'udp',
        src_operator: :eq, src_ip: '192.168.10.3', src_port: 62_223,
        dst_operator: :eq, dst_ip: '11.0.0.3', dst_port: 33_333
      )).to be_nil
    end
  end
end

describe NumberedAcl do
  describe '#initialize' do
    it 'should be error with acl no-integer-acl-number' do
      expect do
        @acl = NumberedAcl.new('a70')
      end.to raise_error(AclArgumentError)
    end
    it 'should be error with invalid number' do
      expect do
        @acl = NumberedAcl.new(33.3)
      end.to raise_error(AclArgumentError)
    end
  end
end

describe NumberedExtAcl do
  describe '#add_entry' do
    before(:all) do
      @acl = NumberedExtAcl.new 102
    end

    it 'should be zero when initialized' do
      expect(@acl.size).to be_zero
      expect(@acl.named_acl?).to be_falsey
      expect(@acl.numbered_acl?).to be_truthy
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
      expect(@acl.size).to eq 1
      aclstr = <<'EOL'
access-list 102 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
    end
  end

  describe '#add_entry_by_params' do
    before(:all) do
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
          port: AceUdpProtoSpec.new(32_768)
        }
      )
    end

    it 'should be size 2' do
      expect(@acl.size).to eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
access-list 104 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
access-list 104 deny tcp host 192.168.3.3 192.168.4.0 0.0.0.255 gt 32768
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
    end

    it 'mutches aclstr with remark' do
      rmk = RemarkAce.new ' this is remark!!'
      @acl.add_entry rmk
      aclstr = <<'EOL'
access-list 104 permit udp 192.168.3.0 0.0.0.127 192.168.4.0 0.0.0.255
access-list 104 deny tcp host 192.168.3.3 192.168.4.0 0.0.0.255 gt 32768
access-list 104 remark this is remark!!
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
