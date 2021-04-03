# frozen_string_literal: true

require 'spec_helper'

describe 'AcePortOpAny' do
  describe '#contains' do
    before(:all) do
      @aclop = AcePortOpAny.new
      @port1 = AceTcpProtoSpec.new(10)
      @port2 = AceTcpProtoSpec.new('www')
    end

    it 'should be true all conditions' do
      expect(@aclop.contains?(AcePortOpAny.new)).to be_truthy
      expect(@aclop.contains?(AcePortOpStrictAny.new)).to be_truthy
      expect(@aclop.contains?(AcePortOpEq.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpNeq.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpLt.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpGt.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2))).to be_truthy
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
      expect(@aclop.contains?(AcePortOpAny.new)).to be_truthy
      expect(@aclop.contains?(AcePortOpStrictAny.new)).to be_truthy
    end

    it 'should be false with other operators' do
      expect(@aclop.contains?(AcePortOpEq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpLt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2))).to be_falsey
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

    it 'should be false with (STRICT_)ANY' do
      expect(@aclop.contains?(AcePortOpAny.new)).to be_falsey
      expect(@aclop.contains?(AcePortOpStrictAny.new)).to be_falsey
    end

    it 'should be true when same eq/port operator' do
      expect(@aclop.contains?(AcePortOpEq.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpEq.new(@port2))).to be_falsey
    end

    it 'should be false with other operator' do
      expect(@aclop.contains?(AcePortOpNeq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpLt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2))).to be_falsey
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

    it 'should be false with (STRICT_)ANY' do
      expect(@aclop.contains?(AcePortOpAny.new)).to be_falsey
      expect(@aclop.contains?(AcePortOpStrictAny.new)).to be_falsey
    end

    it 'should be checked with EQUAL' do
      expect(@aclop.contains?(AcePortOpEq.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpEq.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpEq.new(@port3))).to be_truthy
    end

    it 'should be checked with NOT_EQUAL' do
      expect(@aclop.contains?(AcePortOpNeq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port2))).to be_truthy
      expect(@aclop.contains?(AcePortOpNeq.new(@port3))).to be_falsey
    end

    it 'should be checked with LOWER_THAN' do
      expect(@aclop.contains?(AcePortOpLt.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpLt.new(@port2))).to be_truthy
      expect(@aclop.contains?(AcePortOpLt.new(@port3))).to be_falsey
    end

    it 'should be checked with GRATER_THAN' do
      expect(@aclop.contains?(AcePortOpGt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port2))).to be_truthy
      expect(@aclop.contains?(AcePortOpGt.new(@port3))).to be_truthy
    end

    it 'should be checked with RANGE' do
      port2a = AceTcpProtoSpec.new(79)
      port2b = AceTcpProtoSpec.new(81)
      expect(@aclop.contains?(AcePortOpRange.new(@port1, port2a))).to be_truthy
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port2, @port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(port2b, @port3))).to be_truthy
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port3))).to be_falsey
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

    it 'should be false with (STRICT_)ANY' do
      expect(@aclop.contains?(AcePortOpAny.new)).to be_falsey
      expect(@aclop.contains?(AcePortOpStrictAny.new)).to be_falsey
    end

    it 'should be checked with EQUAL' do
      expect(@aclop.contains?(AcePortOpEq.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpEq.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpEq.new(@port3))).to be_falsey
    end

    it 'should be checked with NOT_EQUAL(1)' do
      expect(@aclop.contains?(AcePortOpNeq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port3))).to be_falsey
    end

    it 'should be checked with NOT_EQUAL(2)' do
      aclop = AcePortOpLt.new(@port_max)
      expect(aclop.contains?(AcePortOpNeq.new(@port_max))).to be_truthy
    end

    it 'should be checked with LOWER_THAN' do
      expect(@aclop.contains?(AcePortOpLt.new(@port1))).to be_truthy
      expect(@aclop.contains?(AcePortOpLt.new(@port2))).to be_truthy
      expect(@aclop.contains?(AcePortOpLt.new(@port3))).to be_falsey
    end

    it 'should be checked with GRATER_THAN' do
      expect(@aclop.contains?(AcePortOpGt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port3))).to be_falsey
    end

    it 'should be checked with RANGE' do
      port2a = AceTcpProtoSpec.new(79)
      port2b = AceTcpProtoSpec.new(81)
      expect(@aclop.contains?(AcePortOpRange.new(@port1, port2a))).to be_truthy
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port2, @port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(port2b, @port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port3))).to be_falsey
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

    it 'should be false with (STRICT_)ANY' do
      expect(@aclop.contains?(AcePortOpAny.new)).to be_falsey
      expect(@aclop.contains?(AcePortOpStrictAny.new)).to be_falsey
    end

    it 'should be checked with EQUAL' do
      expect(@aclop.contains?(AcePortOpEq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpEq.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpEq.new(@port3))).to be_truthy
    end

    it 'should be checked with NOT_EQUAL(1)' do
      expect(@aclop.contains?(AcePortOpNeq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port3))).to be_falsey
    end

    it 'should be checked with NOT_EQUAL(2)' do
      aclop = AcePortOpGt.new(@port_min)
      expect(aclop.contains?(AcePortOpNeq.new(@port_min))).to be_truthy
    end

    it 'should be checked with LOWER_THAN' do
      expect(@aclop.contains?(AcePortOpLt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpLt.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpLt.new(@port3))).to be_falsey
    end

    it 'should be checked with GRATER_THAN' do
      expect(@aclop.contains?(AcePortOpGt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port2))).to be_truthy
      expect(@aclop.contains?(AcePortOpGt.new(@port3))).to be_truthy
    end

    it 'should be checked with RANGE' do
      port2a = AceTcpProtoSpec.new(79)
      port2b = AceTcpProtoSpec.new(81)
      expect(@aclop.contains?(AcePortOpRange.new(@port1, port2a))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port2, @port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(port2b, @port3))).to be_truthy
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port3))).to be_falsey
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
      @aclop_any = AcePortOpRange.new(@port_min, @port_max)
    end

    it 'should be checked with ANY' do
      expect(@aclop.contains?(AcePortOpAny.new)).to be_falsey
      expect(@aclop_any.contains?(AcePortOpAny.new)).to be_truthy
    end

    it 'should be false with STRICT_ANY' do
      expect(@aclop.contains?(AcePortOpStrictAny.new)).to be_falsey
      expect(@aclop_any.contains?(AcePortOpStrictAny.new)).to be_falsey
    end

    it 'should be checked with EQUAL' do
      expect(@aclop.contains?(AcePortOpEq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpEq.new(@port2))).to be_truthy
      expect(@aclop.contains?(AcePortOpEq.new(@port3))).to be_truthy
      expect(@aclop.contains?(AcePortOpEq.new(@port4))).to be_falsey
    end

    it 'should be checked with NOT_EQUAL(1)' do
      expect(@aclop.contains?(AcePortOpNeq.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpNeq.new(@port4))).to be_falsey
    end

    it 'should be checked with NOT_EQUAL(2)' do
      aclop = AcePortOpRange.new(@port_min, @port_max)
      expect(aclop.contains?(AcePortOpNeq.new(@port_min))).to be_truthy
      expect(aclop.contains?(AcePortOpNeq.new(@port_max))).to be_truthy
    end

    it 'should be checked with LOWER_THAN(1)' do
      expect(@aclop.contains?(AcePortOpLt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpLt.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpLt.new(@port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpLt.new(@port4))).to be_falsey
    end

    it 'should be checked with LOWER_THAN(2)' do
      aclop = AcePortOpRange.new(@port_min, @port3)
      expect(aclop.contains?(AcePortOpLt.new(@port3a))).to be_truthy
      expect(aclop.contains?(AcePortOpLt.new(@port3))).to be_falsey
      expect(aclop.contains?(AcePortOpLt.new(@port3b))).to be_falsey
    end

    it 'should be checked with GRATER_THAN(1)' do
      expect(@aclop.contains?(AcePortOpGt.new(@port1))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpGt.new(@port4))).to be_falsey
    end

    it 'should be checked with GRATER_THAN(2)' do
      aclop = AcePortOpRange.new(@port2, @port_max)
      expect(aclop.contains?(AcePortOpGt.new(@port2a))).to be_falsey
      expect(aclop.contains?(AcePortOpGt.new(@port2))).to be_falsey
      expect(aclop.contains?(AcePortOpGt.new(@port2b))).to be_truthy
    end

    it 'should be checked with RANGE' do
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2a))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port2))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port2, @port3a))).to be_truthy
      expect(@aclop.contains?(AcePortOpRange.new(@port2, @port3))).to be_truthy
      expect(@aclop.contains?(AcePortOpRange.new(@port2, @port3b))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port3))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port2, @port4))).to be_falsey
      expect(@aclop.contains?(AcePortOpRange.new(@port1, @port4))).to be_falsey
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
