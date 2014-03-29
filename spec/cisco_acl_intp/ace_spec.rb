# -*- coding: utf-8 -*-
require 'spec_helper'

describe RemarkAce do
  describe '#to_s' do
    it 'should be remark string' do
      rmk = RemarkAce.new('  foo-bar _ baz @@ COMMENT')
      rmk.to_s.should eq 'remark foo-bar _ baz @@ COMMENT'
    end
  end

  describe '#==' do
    before(:all) do
      @rmk1 = RemarkAce.new('asdfjklj;')
      @rmk2 = RemarkAce.new('asdfjklj;')
      @rmk3 = RemarkAce.new('asd f j klj;')
    end

    it 'should be true when same comment' do
      (@rmk1 == @rmk2).should be_true
    end

    it 'should be false when different comment' do
      (@rmk1 == @rmk3).should be_false
    end
  end

  describe '#contains?' do
    it 'should be always false' do
      rmk = RemarkAce.new('asdfjklj;')
      rmk.contains?(
        src_ip: '192.168.4.4',
        dst_ip: '172.30.240.33'
      ).should be_false
      # with empty argments
      rmk.contains?.should be_false
    end
  end
end

describe EvaluateAce do
  describe '#to_s' do
    it 'should be evaluate term' do
      evl = EvaluateAce.new(
        recursive_name: 'foobar_baz'
      )
      evl.to_s.should be_aclstr('evaluate foobar_baz')
    end

    it 'raise error if not specified recursive name' do
      lambda do
        EvaluateAce.new(
          number: 30
        )
      end.should raise_error(AclArgumentError)
    end
  end

  describe '#==' do
    before(:all) do
      @evl1 = EvaluateAce.new(recursive_name: 'foo_bar')
      @evl2 = EvaluateAce.new(recursive_name: 'foo_bar')
      @evl3 = EvaluateAce.new(recursive_name: 'foo_baz')
    end

    it 'should be true when same evaluate name' do
      (@evl1 == @evl2).should be_true
    end

    it 'should be false when different evaluate name' do
      (@evl1 == @evl3).should be_false
    end
  end

  describe '#contains?' do
    it 'should be false' do
      pending('match by evaluate is not implemented yet')

      evl = EvaluateAce.new(
        recursive_name: 'asdf_0-98'
      )
      evl.contains?(
        src_ip: '192.168.4.4',
        dst_ip: '172.30.240.33'
      ).should be_false
      # with empty argments
      evl.contains?.should be_false
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
