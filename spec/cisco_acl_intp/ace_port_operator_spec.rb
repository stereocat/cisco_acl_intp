# -*- coding: utf-8 -*-
require 'spec_helper'

describe 'AcePortOpAny' do
  describe '#contains' do
    before(:all) do
      @aclop = AcePortOpAny.new
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
    end

    it 'should be true all conditions' do
      @aclop.contains?(AcePortOpAny.new).should be_true
      @aclop.contains?(AcePortOpStrictAny.new).should be_true
      @aclop.contains?(AcePortOpEq.new(@port1)).should be_true
      @aclop.contains?(AcePortOpNeq.new(@port1)).should be_true
      @aclop.contains?(AcePortOpLt.new(@port1)).should be_true
      @aclop.contains?(AcePortOpGt.new(@port1)).should be_true
      @aclop.contains?(AcePortOpRange.new(@port1, @port2)).should be_true
    end
  end
end

describe 'AcePortOpStrictAny' do
  describe '#contains' do
    before(:all) do
      @aclop = AcePortOpStrictAny.new
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
    end

    it 'should be true when only ANY conditions' do
      @aclop.contains?(AcePortOpAny.new).should be_true
      @aclop.contains?(AcePortOpStrictAny.new).should be_true
    end

    it 'should be false with other operators' do
      @aclop.contains?(AcePortOpEq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpLt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port1, @port2)).should be_false
    end
  end
end

describe 'AcePortOpEq' do
  describe '#contains' do
    before(:all) do
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
      @aclop = AcePortOpEq.new(@port1)
    end

    it 'should be true with ANY' do
      @aclop.contains?(AcePortOpAny.new).should be_true
    end

    it 'should be false with STRICT_ANY' do
      @aclop.contains?(AcePortOpStrictAny.new).should be_true
    end

    it 'should be true when same eq/port operator' do
      @aclop.contains?(AcePortOpEq.new(@port1)).should be_true
      @aclop.contains?(AcePortOpEq.new(@port2)).should be_false
    end

    it 'should be false with other operator' do
      @aclop.contains?(AcePortOpNeq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpLt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port1, @port2)).should be_false
    end
  end
end

describe 'AcePortOpNeq' do
  describe '#contains' do
    before(:all) do
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
      @port3 = AceTcpProtoSpec.new(443)
      @aclop = AcePortOpNeq.new(@port2)
    end

    it 'should be true with ANY' do
      @aclop.contains?(AcePortOpAny.new).should be_true
    end

    it 'should be false with STRICT_ANY' do
      @aclop.contains?(AcePortOpStrictAny.new).should be_true
    end

    it 'should be checked with EQUAL' do
      @aclop.contains?(AcePortOpEq.new(@port1)).should be_true
      @aclop.contains?(AcePortOpEq.new(@port2)).should be_false
      @aclop.contains?(AcePortOpEq.new(@port3)).should be_true
    end

    it 'should be checked with NOT_EQUAL' do
      @aclop.contains?(AcePortOpNeq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port2)).should be_true
      @aclop.contains?(AcePortOpNeq.new(@port3)).should be_false
    end

    it 'should be checked with LOWER_THAN' do
      @aclop.contains?(AcePortOpLt.new(@port1)).should be_true
      @aclop.contains?(AcePortOpLt.new(@port2)).should be_true
      @aclop.contains?(AcePortOpLt.new(@port3)).should be_false
    end

    it 'should be checked with GRATER_THAN' do
      @aclop.contains?(AcePortOpGt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port2)).should be_true
      @aclop.contains?(AcePortOpGt.new(@port3)).should be_true
    end

    it 'should be checked with RANGE' do
      port2a = AceTcpProtoSpec.new(79)
      port2b = AceTcpProtoSpec.new(81)
      @aclop.contains?(AcePortOpRange.new(@port1, port2a)).should be_true
      @aclop.contains?(AcePortOpRange.new(@port1, @port2)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port2, @port3)).should be_false
      @aclop.contains?(AcePortOpRange.new(port2b, @port3)).should be_true
      @aclop.contains?(AcePortOpRange.new(@port1, @port3)).should be_false
    end
  end
end

describe 'AcePortOpLt' do
  describe '#contains' do
    before(:all) do
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
      @port3 = AceTcpProtoSpec.new(443)
      @port_max = AceTcpProtoSpec.new(65_535)
      @aclop = AcePortOpLt.new(@port2)
    end

    it 'should be true with ANY' do
      @aclop.contains?(AcePortOpAny.new).should be_true
    end

    it 'should be false with STRICT_ANY' do
      @aclop.contains?(AcePortOpStrictAny.new).should be_true
    end

    it 'should be checked with EQUAL' do
      @aclop.contains?(AcePortOpEq.new(@port1)).should be_true
      @aclop.contains?(AcePortOpEq.new(@port2)).should be_false
      @aclop.contains?(AcePortOpEq.new(@port3)).should be_false
    end

    it 'should be checked with NOT_EQUAL(1)' do
      @aclop.contains?(AcePortOpNeq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port2)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port3)).should be_false
    end

    it 'should be checked with NOT_EQUAL(2)' do
      aclop = AcePortOpLt.new(@port_max)
      aclop.contains?(AcePortOpNeq.new(@port_max)).should be_true
    end

    it 'should be checked with LOWER_THAN' do
      @aclop.contains?(AcePortOpLt.new(@port1)).should be_true
      @aclop.contains?(AcePortOpLt.new(@port2)).should be_true
      @aclop.contains?(AcePortOpLt.new(@port3)).should be_false
    end

    it 'should be checked with GRATER_THAN' do
      @aclop.contains?(AcePortOpGt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port2)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port3)).should be_false
    end

    it 'should be checked with RANGE' do
      port2a = AceTcpProtoSpec.new(79)
      port2b = AceTcpProtoSpec.new(81)
      @aclop.contains?(AcePortOpRange.new(@port1, port2a)).should be_true
      @aclop.contains?(AcePortOpRange.new(@port1, @port2)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port2, @port3)).should be_false
      @aclop.contains?(AcePortOpRange.new(port2b, @port3)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port1, @port3)).should be_false
    end
  end
end

describe 'AcePortOpGt' do
  describe '#contains' do
    before(:all) do
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
      @port3 = AceTcpProtoSpec.new(443)
      @port_min = AceTcpProtoSpec.new(0)
      @aclop = AcePortOpGt.new(@port2)
    end

    it 'should be true with ANY' do
      @aclop.contains?(AcePortOpAny.new).should be_true
    end

    it 'should be false with STRICT_ANY' do
      @aclop.contains?(AcePortOpStrictAny.new).should be_true
    end

    it 'should be checked with EQUAL' do
      @aclop.contains?(AcePortOpEq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpEq.new(@port2)).should be_false
      @aclop.contains?(AcePortOpEq.new(@port3)).should be_true
    end

    it 'should be checked with NOT_EQUAL(1)' do
      @aclop.contains?(AcePortOpNeq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port2)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port3)).should be_false
    end

    it 'should be checked with NOT_EQUAL(2)' do
      aclop = AcePortOpGt.new(@port_min)
      aclop.contains?(AcePortOpNeq.new(@port_min)).should be_true
    end

    it 'should be checked with LOWER_THAN' do
      @aclop.contains?(AcePortOpLt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpLt.new(@port2)).should be_false
      @aclop.contains?(AcePortOpLt.new(@port3)).should be_false
    end

    it 'should be checked with GRATER_THAN' do
      @aclop.contains?(AcePortOpGt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port2)).should be_true
      @aclop.contains?(AcePortOpGt.new(@port3)).should be_true
    end

    it 'should be checked with RANGE' do
      port2a = AceTcpProtoSpec.new(79)
      port2b = AceTcpProtoSpec.new(81)
      @aclop.contains?(AcePortOpRange.new(@port1, port2a)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port1, @port2)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port2, @port3)).should be_false
      @aclop.contains?(AcePortOpRange.new(port2b, @port3)).should be_true
      @aclop.contains?(AcePortOpRange.new(@port1, @port3)).should be_false
    end
  end
end

describe 'AcePortOpRange' do
  describe '#contains' do
    before(:all) do
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
      @port3 = AceTcpProtoSpec.new(443)
      @port4 = AceTcpProtoSpec.new(8080)

      @port2a = AceTcpProtoSpec.new(79)
      @port2b = AceTcpProtoSpec.new(81)
      @port3a = AceTcpProtoSpec.new(442)
      @port3b = AceTcpProtoSpec.new(444)

      @port_max = AceTcpProtoSpec.new(65_535)
      @port_min = AceTcpProtoSpec.new(0)

      @aclop = AcePortOpRange.new(@port2, @port3)
    end

    it 'should be true with ANY' do
      @aclop.contains?(AcePortOpAny.new).should be_true
    end

    it 'should be false with STRICT_ANY' do
      @aclop.contains?(AcePortOpStrictAny.new).should be_true
    end

    it 'should be checked with EQUAL' do
      @aclop.contains?(AcePortOpEq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpEq.new(@port2)).should be_true
      @aclop.contains?(AcePortOpEq.new(@port3)).should be_true
      @aclop.contains?(AcePortOpEq.new(@port4)).should be_false
    end

    it 'should be checked with NOT_EQUAL(1)' do
      @aclop.contains?(AcePortOpNeq.new(@port1)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port2)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port3)).should be_false
      @aclop.contains?(AcePortOpNeq.new(@port4)).should be_false
    end

    it 'should be checked with NOT_EQUAL(2)' do
      aclop = AcePortOpRange.new(@port_min, @port_max)
      aclop.contains?(AcePortOpNeq.new(@port_min)).should be_true
      aclop.contains?(AcePortOpNeq.new(@port_max)).should be_true
    end

    it 'should be checked with LOWER_THAN(1)' do
      @aclop.contains?(AcePortOpLt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpLt.new(@port2)).should be_false
      @aclop.contains?(AcePortOpLt.new(@port3)).should be_false
      @aclop.contains?(AcePortOpLt.new(@port4)).should be_false
    end

    it 'should be checked with LOWER_THAN(2)' do
      aclop = AcePortOpRange.new(@port_min, @port3)
      aclop.contains?(AcePortOpLt.new(@port3a)).should be_true
      aclop.contains?(AcePortOpLt.new(@port3)).should be_false
      aclop.contains?(AcePortOpLt.new(@port3b)).should be_false
    end

    it 'should be checked with GRATER_THAN(1)' do
      @aclop.contains?(AcePortOpGt.new(@port1)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port2)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port3)).should be_false
      @aclop.contains?(AcePortOpGt.new(@port4)).should be_false
    end

    it 'should be checked with GRATER_THAN(2)' do
      aclop = AcePortOpRange.new(@port2, @port_max)
      aclop.contains?(AcePortOpGt.new(@port2a)).should be_false
      aclop.contains?(AcePortOpGt.new(@port2)).should be_false
      aclop.contains?(AcePortOpGt.new(@port2b)).should be_true
    end

    it 'should be checked with RANGE' do
      @aclop.contains?(AcePortOpRange.new(@port1, @port2a)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port1, @port2)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port2, @port3a)).should be_true
      @aclop.contains?(AcePortOpRange.new(@port2, @port3)).should be_true
      @aclop.contains?(AcePortOpRange.new(@port2, @port3b)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port1, @port3)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port2, @port4)).should be_false
      @aclop.contains?(AcePortOpRange.new(@port1, @port4)).should be_false
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
