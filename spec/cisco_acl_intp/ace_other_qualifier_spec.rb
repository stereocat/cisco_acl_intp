# -*- coding: utf-8 -*-
require 'spec_helper'

describe AceLogSpec do
  describe '#==' do
    before(:all) do
      @log1 = AceLogSpec.new
      @log2 = AceLogSpec.new('hoge')
      @log3 = AceLogSpec.new('hoge')
    end

    it 'should be true when same cookie' do
      expect(@log2 == @log3).to be_truthy
    end

    it 'should be false when different cookie' do
      expect(@log2 == @log1).to be_falsey
    end
  end

  describe '#to_s' do
    it 'should be log without cookie' do
      log = AceLogSpec.new
      expect(log.to_s).to be_aclstr('log')
    end

    it 'should be log-input without cookie string' do
      log = AceLogSpec.new('', true)
      expect(log.to_s).to be_aclstr('log-input')
    end

    it 'should be log with cookie' do
      log = AceLogSpec.new('Cookie0123')
      expect(log.to_s).to be_aclstr('log Cookie0123')
    end

    it 'should be log-input with cookie string' do
      log = AceLogSpec.new('log', true)
      expect(log.to_s).to be_aclstr('log-input log')
    end
  end
end

describe AceRecursiveQualifier do
  describe '#==' do
    before(:all) do
      @rcsv1 = AceLogSpec.new
      @rcsv2 = AceLogSpec.new('hoge')
      @rcsv3 = AceLogSpec.new('hoge')
    end

    it 'should be true when same recursive-name' do
      expect(@rcsv2 == @rcsv3).to be_truthy
    end

    it 'should be false when different recursive-name' do
      expect(@rcsv2 == @rcsv1).to be_falsey
    end
  end

  describe '#to_s' do
    it 'should be reflect spec string' do
      rcsv = AceRecursiveQualifier.new('established')
      expect(rcsv.to_s).to be_aclstr('reflect established')
    end

    it 'should be raised error' do
      expect do
        AceRecursiveQualifier.new('')
      end.to raise_error(AclArgumentError)
    end
  end
end

describe AceOtherQualifierList do
  describe '#to_s' do
    before(:all) do
      @oq1 = AceLogSpec.new
      @oq2 = AceRecursiveQualifier.new('iptraffic')
      @list = AceOtherQualifierList.new
    end

    it 'should be size 0 when empty list'do
      expect(@list.size).to be_zero
    end

    it 'should count-up size when added AceTcpFlag objects' do
      @list.push @oq1
      expect(@list.size).to eq 1
      @list.push @oq2
      expect(@list.size).to eq 2
      expect(@list.to_s).to be_aclstr('log reflect iptraffic')
    end
  end

  describe '#==' do
    before(:all) do
      log1 = AceLogSpec.new
      log2 = AceLogSpec.new('hoge')
      rcsv1 = AceRecursiveQualifier.new('iptraffic')
      @list1 = AceOtherQualifierList.new([log1, rcsv1])
      @list2 = AceOtherQualifierList.new([rcsv1, log1])
      @list3 = AceOtherQualifierList.new([log2, rcsv1])
    end

    it 'should be true when same other qualifier elements' do
      expect(@list1 == @list2).to be_truthy
    end

    it 'should be false when different other qualifier elements' do
      expect(@list1 == @list3).to be_falsey
    end
  end
end
