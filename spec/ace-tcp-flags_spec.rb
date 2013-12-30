# -*- coding: utf-8 -*-

require 'spec_helper'

include CiscoAclIntp
AclContainerBase.disable_color

describe AceTcpFlag do
  describe '#to_s' do

    it 'should be make tcp flags' do
      flag = AceTcpFlag.new('established')
      flag.to_s.should be_aclstr('established')
    end
  end
end

describe AceTcpFlagList do
  describe '#to_s' do

    before do
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
end
