# -*- coding: utf-8 -*-
require 'spec_helper'

describe RemarkAce do
  describe '#to_s' do
    it 'should be remark string' do
      rmk = RemarkAce.new('  foo-bar _ baz @@ COMMENT')
      expect(rmk.to_s).to eq 'remark foo-bar _ baz @@ COMMENT'
    end
  end

  describe '#==' do
    before(:all) do
      @rmk1 = RemarkAce.new('asdfjklj;')
      @rmk2 = RemarkAce.new('asdfjklj;')
      @rmk3 = RemarkAce.new('asd f j klj;')
    end

    it 'should be true when same comment' do
      expect(@rmk1 == @rmk2).to be_truthy
    end

    it 'should be false when different comment' do
      expect(@rmk1 == @rmk3).to be_falsey
    end
  end

  describe '#contains?' do
    it 'should be always false' do
      rmk = RemarkAce.new('asdfjklj;')
      expect(
        rmk.contains?(
          src_ip: '192.168.4.4',
          dst_ip: '172.30.240.33'
        )).to be_falsey
      # with empty argments
      expect(rmk.contains?).to be_falsey
    end
  end
end

describe EvaluateAce do
  describe '#to_s' do
    it 'should be evaluate term' do
      evl = EvaluateAce.new(
        recursive_name: 'foobar_baz'
      )
      expect(evl.to_s).to be_aclstr('evaluate foobar_baz')
    end

    it 'raise error if not specified recursive name' do
      expect do
        EvaluateAce.new(
          number: 30
        )
      end.to raise_error(AclArgumentError)
    end
  end

  describe '#==' do
    before(:all) do
      @evl1 = EvaluateAce.new(recursive_name: 'foo_bar')
      @evl2 = EvaluateAce.new(recursive_name: 'foo_bar')
      @evl3 = EvaluateAce.new(recursive_name: 'foo_baz')
    end

    it 'should be true when same evaluate name' do
      expect(@evl1 == @evl2).to be_truthy
    end

    it 'should be false when different evaluate name' do
      expect(@evl1 == @evl3).to be_falsey
    end
  end

  describe '#contains?' do
    it 'should be false' do
      skip('match by evaluate is not implemented yet')

      evl = EvaluateAce.new(
        recursive_name: 'asdf_0-98'
      )
      expect(
        evl.contains?(
          src_ip: '192.168.4.4',
          dst_ip: '172.30.240.33'
        )).to be_falsey
      # with empty argments
      expect(evl.contains?).to be_falsey
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
