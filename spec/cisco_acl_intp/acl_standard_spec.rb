# -*- coding: utf-8 -*-
require 'spec_helper'

describe NamedStdAcl do
  describe '#add_entry' do
    before(:all) do
      @acl = NamedStdAcl.new 'test-std-acl'
    end

    it 'should be zero when initialized' do
      expect(@acl.size).to be_zero
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
      expect(@acl.size).to eq 1
      aclstr = <<'EOL'
ip access-list standard test-std-acl
 permit 192.168.3.0 0.0.0.127
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
    end
  end

  describe '#add_entry_by_params' do
    before(:all) do
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
      expect(@acl.size).to eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
ip access-list standard test-std-acl2
 permit 192.168.3.0 0.0.0.127
 deny 192.168.4.0 0.0.0.255
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
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
      expect(@acl.to_s).to be_aclstr(aclstr)
    end
  end

  describe '#find_aces_contains' do
    # for standard ace, it is same as named/numbered ace.
    # so that, tests only named-standard-ace
    # and omit numbered-standard-acl
    before(:all) do
      @acl = NamedStdAcl.new 'test-stdacl3'
      @acl.add_entry_by_params(
        action: 'permit',
        src: { ipaddr: '192.168.3.3', wildcard: '0.0.0.127' }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        src: { ipaddr: '192.168.10.3', wildcard: '0.0.0.0' }
      )
      @acl.add_entry_by_params(
        action: 'deny',
        src: { ipaddr: '10.0.0.0', wildcard: '0.0.0.255' }
      )
    end

    it 'should be match 2nd entry' do
      ace = @acl.find_aces_contains(
        protocol: 'tcp',
        src_operator: :eq, src_ip: '192.168.10.3', src_port: 64_332
      )
      expect(ace.to_s).to be_aclstr('deny host 192.168.10.3')
    end

    it 'should be last entry' do
      ace = @acl.find_aces_contains(
        protocol: 'tcp',
        src_operator: :eq, src_ip: '10.0.0.3', src_port: 33_890
      )
      expect(ace.to_s).to be_aclstr('deny 10.0.0.0 0.0.0.255')
    end

    it 'should be nil if not found match entry' do
      expect(
        @acl.find_aces_contains(
          protocol: 'udp',
          src_operator: :eq, src_ip: '11.0.0.3', src_port: 33_333
        )).to be_nil
    end
  end
end

describe NumberedStdAcl do
  describe '#add_entry' do
    before(:all) do
      @acl = NumberedStdAcl.new 10
    end

    it 'should be zero when initialized' do
      expect(@acl.size).to be_zero
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
      expect(@acl.size).to eq 1
      aclstr = <<'EOL'
access-list 10 permit 192.168.3.0 0.0.0.127
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
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
      expect(@acl.size).to eq 2
    end

    it 'mutches aclstr' do
      aclstr = <<'EOL'
access-list 14 permit 192.168.3.0 0.0.0.127
access-list 14 deny 192.168.4.0 0.0.0.255
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
    end

    it 'mutches aclstr with remark' do
      rmk = RemarkAce.new ' this is remark!!'
      @acl.add_entry rmk
      aclstr = <<'EOL'
access-list 14 permit 192.168.3.0 0.0.0.127
access-list 14 deny 192.168.4.0 0.0.0.255
access-list 14 remark this is remark!!
EOL
      expect(@acl.to_s).to be_aclstr(aclstr)
    end
  end

  context 'list operations' do
    before do
      @acl = NumberedStdAcl.new 15
      @acl.add_entry RemarkAce.new('entry 1')
      @acl.add_entry RemarkAce.new('entry 2')
      @acl.add_entry RemarkAce.new('entry 3')
      @acl.add_entry RemarkAce.new('entry 4')
    end

    describe '#renumber' do
      it 'should has seq number by add_entry' do
        @acl.renumber
        @acl.reduce(10) do |num, each|
          expect(each.seq_number).to eq num
          num + 10
        end
      end
    end

    describe '#sort' do
      it 'should be sorted by seq number' do
        @acl.renumber # initialize seq number

        last_ace = @acl.pop
        last_ace.seq_number = 15
        @acl.add_entry last_ace
        acl_new = @acl.dup_with_list(@acl.sort)

        aclstr = <<'EOL'
access-list 15 remark entry 1
access-list 15 remark entry 2
access-list 15 remark entry 3
access-list 15 remark entry 4
EOL
        aclstr_new = <<'EOL'
access-list 15 remark entry 1
access-list 15 remark entry 4
access-list 15 remark entry 2
access-list 15 remark entry 3
EOL
        expect(@acl.name).to eq acl_new.name
        expect(@acl.acl_type).to eq acl_new.acl_type
        expect(@acl.to_s).to be_aclstr(aclstr)
        expect(acl_new.to_s).to be_aclstr(aclstr_new)
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
