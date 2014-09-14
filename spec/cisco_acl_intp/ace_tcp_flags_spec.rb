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
      expect(@flag.to_s).to be_aclstr('established')
    end

    it 'should be true when same flag' do
      expect(@flag == @flag1).to be_truthy
    end

    it 'should not false when different flag' do
      expect(@flag == @flag2).to be_falsey
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
      expect(@list.size).to be_zero
    end

    it 'should count-up size when added AceTcpFlag objects' do
      @list.push @f1
      expect(@list.size).to eq 1
      @list.push @f2
      expect(@list.size).to eq 2
      @list.push @f3
      expect(@list.size).to eq 3
      expect(@list.to_s).to be_aclstr('syn ack established')
    end
  end

  describe '#==' do
    before(:all) do
      @f1 = AceTcpFlag.new('syn')
      @f2 = AceTcpFlag.new('ack')
      @f3 = AceTcpFlag.new('established')
      @f4 = AceTcpFlag.new('fin')

      @list1 = AceTcpFlagList.new([@f1, @f2, @f3])
      @list2 = AceTcpFlagList.new([@f3, @f1, @f2])
      @list3 = AceTcpFlagList.new([@f2, @f4, @f1])
    end

    it 'should be true when same list' do
      expect(@list1 == @list2).to be_truthy
    end

    it 'should be false when different list' do
      expect(@list1 == @list3).to be_falsey
    end
  end
end
