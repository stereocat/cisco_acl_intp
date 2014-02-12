# -*- coding: utf-8 -*-
require 'spec_helper'

describe AceTcpFlag do
  describe '#to_s' do
    before do
      @flag = AceTcpFlag.new('established')
      @flag1 = AceTcpFlag.new('established')
      @flag2 = AceTcpFlag.new('rst')
    end

    it 'should be make tcp flags' do
      @flag.to_s.should be_aclstr('established')
    end

    it 'should be true when same flag' do
      (@flag == @flag1).should be_true
    end

    it 'should not false when different flag' do
      (@flag == @flag2).should be_false
    end
  end
end

describe AceTcpFlagList do
  describe '#to_s' do
    before(:all) do
      @f1 = AceTcpFlag.new('syn')
      @f2 = AceTcpFlag.new('ack')
      @f3 = AceTcpFlag.new('established')
      @list = AceTcpFlagList.new
    end

    it 'should be size 0 when empty list' do
      @list.size.should be_zero
    end

    it 'should count-up size when added AceTcpFlag objects' do
      @list.push @f1
      @list.size.should eq 1
      @list.push @f2
      @list.size.should eq 2
      @list.push @f3
      @list.size.should eq 3
      @list.to_s.should be_aclstr('syn ack established')
    end
  end

  describe '#==' do
    before(:all) do
      @f1 = AceTcpFlag.new('syn')
      @f2 = AceTcpFlag.new('ack')
      @f3 = AceTcpFlag.new('established')
      @f4 = AceTcpFlag.new('fin')

      @list1 = AceTcpFlagList.new(@f1, @f2, @f3)
      @list2 = AceTcpFlagList.new(@f3, @f1, @f2)
      @list3 = AceTcpFlagList.new(@f2, @f4, @f1)
    end

    it 'should be true when same list' do
      (@list1 == @list2).should be_true
    end

    it 'should be false when different list' do
      (@list1 == @list3).should be_false
    end
  end
end
