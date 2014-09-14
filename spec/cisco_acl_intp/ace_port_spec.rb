# -*- coding: utf-8 -*-
require 'spec_helper'

describe AcePortSpec do
  describe '#new' do
    before(:all) do
      @port1 = AceTcpProtoSpec.new('bgp') # 179
      @port2 = AceTcpProtoSpec.new(333)
    end

    it 'shoud be error with unknown operator' do
      expect do
        AcePortSpec.new(
          operator: 'equal',
          port: @port1
        )
      end.to raise_error(AclArgumentError)
    end

    it 'should be error with invalid ports' do
      expect do
        AcePortSpec.new(
          operator: 'range',
          begin_port: @port2,
          end_port: @port1
        )
      end.to raise_error(AclArgumentError)
    end
  end

  describe '#to_s' do
    before(:all) do
      @p1 = AceTcpProtoSpec.new(22)
      @p2 = AceTcpProtoSpec.new('www')
    end

    context 'Normal case' do
      it 'should be "eq 22"' do
        p = AcePortSpec.new(
          operator: 'eq', port: @p1
        )
        expect(p.to_s).to be_aclstr('eq 22')
      end

      it 'should be "lt www"' do
        p = AcePortSpec.new(
          operator: 'lt', port: @p2
        )
        expect(p.to_s).to be_aclstr('lt www')
      end

      it 'should be "gt www"' do
        p = AcePortSpec.new(
          operator: 'gt', port: @p2
        )
        expect(p.to_s).to be_aclstr('gt www')
      end

      it 'should be "range 22 www"' do
        p = AcePortSpec.new(
          operator: 'range',
          begin_port: @p1, end_port: @p2
        )
        expect(p.to_s).to be_aclstr('range 22 www')
      end

      it 'should be empty when any port' do
        p = AcePortSpec.new(
          operator: 'any',
          begin_port: @p1, end_port: @p2
        )
        expect(p.to_s).to be_empty
      end

    end
    context 'Argument error case' do
      it 'raise error when not specified operator' do
        expect do
          AcePortSpec.new(
            end_port: @p1
          )
        end.to raise_error(AclArgumentError)
      end

      it 'raise error when not specified begin_port' do
        expect do
          AcePortSpec.new(
            operator: 'eq',
            end_port: @p1
          )
        end.to raise_error(AclArgumentError)
      end

      it 'raise error when wrong port sequence' do
        expect do
          AcePortSpec.new(
            operator: 'range',
            begin_port: @p2, end_port: @p1
          )
        end.to raise_error(AclArgumentError)
      end
    end
  end

  describe '#contains?' do
    before(:all) do
      @p1 = AceTcpProtoSpec.new(22)
      @p2 = AceTcpProtoSpec.new(32_768)

      @any = AcePortSpec.new(operator: 'any')
      @s_any = AcePortSpec.new(operator: :strict_any)
      @eq1 = AcePortSpec.new(operator: 'eq', begin_port: @p1)
      @eq2 = AcePortSpec.new(operator: 'eq', begin_port: @p2)
      @neq1 = AcePortSpec.new(operator: 'neq', port: @p1)
      @lt1 = AcePortSpec.new(operator: 'lt', port: @p1)
      @lt2 = AcePortSpec.new(operator: 'lt', port: @p2)
      @gt1 = AcePortSpec.new(operator: 'gt', port: @p1)
      @gt2 = AcePortSpec.new(operator: 'gt', port: @p2)
      @range = AcePortSpec.new(
        operator: 'range',
        port: @p1, end_port: @p2
      )
    end

    it 'should be true when contained case' do
      expect(@any.contains?(@eq1)).to be_truthy
      expect(@s_any.contains?(@any)).to be_truthy
      expect(@eq1.contains?(@eq1)).to be_truthy
      expect(@neq1.contains?(@eq2)).to be_truthy
      expect(@lt2.contains?(@lt1)).to be_truthy
      expect(@gt1.contains?(@gt2)).to be_truthy
      expect(@range.contains?(@eq1)).to be_truthy
    end

    it 'should be false when not contained case' do
      expect(@s_any.contains?(@eq1)).to be_falsey
      expect(@eq1.contains?(@eq2)).to be_falsey
      expect(@neq1.contains?(@eq1)).to be_falsey
      expect(@lt1.contains?(@lt2)).to be_falsey
      expect(@gt2.contains?(@lt1)).to be_falsey
      expect(@range.contains?(@neq1)).to be_falsey
    end
  end

  describe '#==' do
    before(:all) do
      @p1a = AceTcpProtoSpec.new(179)
      @p1b = AceTcpProtoSpec.new('bgp')
      @p2  = AceTcpProtoSpec.new(33)
      @pu1 = AceUdpProtoSpec.new(179)
    end

    it 'should be true when same operator, same protocol' do
      a = AcePortSpec.new(operator: 'eq', port: @p1a)
      b = AcePortSpec.new(operator: 'eq', port: @p1b)
      expect(a == b).to be_truthy
    end

    it 'should be false when different protocol' do
      a = AcePortSpec.new(operator: 'eq', port: @p1a)
      b = AcePortSpec.new(operator: 'eq', port: @p2)
      expect(a == b).to be_falsey
    end

    it 'should be false when different operator' do
      a = AcePortSpec.new(operator: 'eq', port: @p2)
      b = AcePortSpec.new(operator: 'lt', port: @p2)
      expect(a == b).to be_falsey
    end

    it 'should be false when different protocol' do
      a = AcePortSpec.new(operator: 'eq', port: @p1a)
      b = AcePortSpec.new(operator: 'eq', port: @pu1)
      expect(a == b).to be_falsey
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
