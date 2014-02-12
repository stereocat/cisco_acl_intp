# -*- coding: utf-8 -*-
require 'spec_helper'

describe AcePortSpec do
  describe '#new' do
    it 'shoud be error with unknown operator' do
      lambda do
        AcePortSpec.new(
          operator: 'equal',
          port: 443
        )
      end.should raise_error(AclArgumentError)
    end

    it 'should be error with invalid ports' do
      lambda do
        AcePortSpec.new(
          operator: 'range',
          begin_port: 443,
          end_port: 139
        )
      end.should raise_error(AclArgumentError)
    end
  end

  describe '#to_s' do
    before(:all) do
      @p1 = AceTcpProtoSpec.new(number: 22)
      @p2 = AceTcpProtoSpec.new(number: 80)
    end

    context 'Normal case' do
      it 'should be "eq 22"' do
        p = AcePortSpec.new(
          operator: 'eq', port: @p1
        )
        p.to_s.should be_aclstr('eq 22')
      end

      it 'should be "lt www"' do
        p = AcePortSpec.new(
          operator: 'lt', port: @p2
        )
        p.to_s.should be_aclstr('lt www')
      end

      it 'should be "gt www"' do
        p = AcePortSpec.new(
          operator: 'gt', port: @p2
        )
        p.to_s.should be_aclstr('gt www')
      end

      it 'should be "range 22 www"' do
        p = AcePortSpec.new(
          operator: 'range',
          begin_port: @p1, end_port: @p2
        )
        p.to_s.should be_aclstr('range 22 www')
      end

      it 'should be empty when any port' do
        p = AcePortSpec.new(
          operator: 'any',
          begin_port: @p1, end_port: @p2
        )
        p.to_s.should be_empty
      end

    end
    context 'Argument error case' do
      it 'raise error when not specified operator' do
        lambda do
          AcePortSpec.new(
            end_port: @p1
          )
        end.should raise_error(AclArgumentError)
      end

      it 'raise error when not specified begin_port' do
        lambda do
          AcePortSpec.new(
            operator: 'eq',
            end_port: @p1
          )
        end.should raise_error(AclArgumentError)
      end

      it 'raise error when wrong port sequence' do
        lambda do
          AcePortSpec.new(
            operator: 'range',
            begin_port: @p2, end_port: @p1
          )
        end.should raise_error(AclArgumentError)
      end
    end
  end

  describe '#matches?' do
    before(:all) do
      @p1 = AceTcpProtoSpec.new(number: 22)
      @p2 = AceTcpProtoSpec.new(number: 32_768)

      @any = AcePortSpec.new(
        operator: 'any'
      )
      @eq1 = AcePortSpec.new(
        operator: 'eq', begin_port: @p1
      )
      @neq1 = AcePortSpec.new(
        operator: 'neq', port: @p1
      )
      @lt1 = AcePortSpec.new(
        operator: 'lt', port: @p1
      )
      @gt1 = AcePortSpec.new(
        operator: 'gt', port: @p1
      )
      @range = AcePortSpec.new(
        operator: 'range',
        port: @p1, end_port: @p2
      )
    end

    it 'should be error with protocol name when not specified protocol' do
      lambda do
        @gt1.matches?('www')
      end.should raise_error(AclArgumentError)
    end

    it 'match any if valid port range' do
      lambda do
        @any.matches?(-1)
      end.should raise_error(AclArgumentError)
      @any.matches?(0).should be_true
      @any.matches?(21).should be_true
      @any.matches?(22).should be_true
      @any.matches?(23).should be_true
      @any.matches?(65_535).should be_true
      lambda do
        @any.matches?(65_536)
      end.should raise_error(AclArgumentError)
    end

    it 'match correct number by op:eq' do
      lambda do
        @eq1.matches?(-1)
      end.should raise_error(AclArgumentError)
      @eq1.matches?(0).should be_false
      @eq1.matches?(21).should be_false
      @eq1.matches?(22).should be_true
      @eq1.matches?(23).should be_false
      @eq1.matches?(65_535).should be_false
      lambda do
        @eq1.matches?(65_536)
      end.should raise_error(AclArgumentError)
    end

    it 'match correct number by op:neq' do
      lambda do
        @neq1.matches?(-1)
      end.should raise_error(AclArgumentError)
      @neq1.matches?(0).should be_true
      @neq1.matches?(21).should be_true
      @neq1.matches?(22).should be_false
      @neq1.matches?(23).should be_true
      @neq1.matches?(65_535).should be_true
      lambda do
        @neq1.matches?(65_536)
      end.should raise_error(AclArgumentError)
    end

    it 'match lower number by op:lt' do
      lambda do
        @lt1.matches?(-1)
      end.should raise_error(AclArgumentError)
      @lt1.matches?(0).should be_true
      @lt1.matches?(21).should be_true
      @lt1.matches?(22).should be_false
      @lt1.matches?(23).should be_false
      @lt1.matches?(65_535).should be_false
      lambda do
        @lt1.matches?(65_536)
      end.should raise_error(AclArgumentError)
    end

    it 'match lower number by op:gt' do
      lambda do
        @gt1.matches?(-1)
      end.should raise_error(AclArgumentError)
      @gt1.matches?(0).should be_false
      @gt1.matches?(21).should be_false
      @gt1.matches?(22).should be_false
      @gt1.matches?(23).should be_true
      @gt1.matches?(65_535).should be_true
      lambda do
        @gt1.matches?(65_536)
      end.should raise_error(AclArgumentError)
    end

    it 'match lower number by op:range' do
      lambda do
        @range.matches?(-1)
      end.should raise_error(AclArgumentError)
      @range.matches?(0).should be_false
      @range.matches?(21).should be_false
      @range.matches?(22).should be_true
      @range.matches?(23).should be_true
      @range.matches?(32_767).should be_true
      @range.matches?(32_768).should be_true
      @range.matches?(32_769).should be_false
      @range.matches?(65_535).should be_false
      lambda do
        @range.matches?(65_536)
      end.should raise_error(AclArgumentError)
    end
  end
end

describe AceTcpPortSpec do
  describe '#==' do
    before(:all) do
      @p1a = AceTcpProtoSpec.new(number: 179)
      @p1b = AceTcpProtoSpec.new(name: 'bgp')
      @p2  = AceTcpProtoSpec.new(number: 33)
    end

    it 'should be true when same operator, same protocol' do
      a = AceTcpPortSpec.new(operator: 'eq', port: @p1a)
      b = AceTcpPortSpec.new(operator: 'eq', port: @p1b)
      (a == b).should be_true
    end

    it 'should be false when different protocol' do
      a = AceTcpPortSpec.new(operator: 'eq', port: @p1a)
      b = AceTcpPortSpec.new(operator: 'eq', port: @p2)
      (a == b).should be_false
    end

    it 'should be false when different operator' do
      a = AceTcpPortSpec.new(operator: 'eq', port: @p2)
      b = AceTcpPortSpec.new(operator: 'lt', port: @p2)
      (a == b).should be_false
    end
  end

  describe '#matches? by class variation' do
    before(:all) do
      @p1 = AceTcpProtoSpec.new(name: 'bgp')
      @p2 = AceTcpProtoSpec.new(number: 19)
      @eq1 = AceTcpPortSpec.new(operator: 'eq', port: @p1)
      @eq2 = AceTcpPortSpec.new(operator: 'eq', port: @p2)
      @any = AceTcpPortSpec.new(operator: 'any')
    end

    it 'should be true by correct String arg' do
      @eq1.matches?(179).should be_true
      @eq1.matches?('179').should be_true
      @eq1.matches?('bgp').should be_true

      @eq2.matches?(19).should be_true
      @eq2.matches?('19').should be_true
      @eq2.matches?('chargen').should be_true

      @any.matches?(3).should be_true
      @any.matches?('55').should be_true
      @any.matches?('www').should be_true
    end

    it 'should be false by wrong String arg' do
      @eq1.matches?(178).should be_false
      @eq1.matches?('178').should be_false

      @eq2.matches?(18).should be_false
      @eq2.matches?('18').should be_false
    end

    it 'should be raise error by unknown arg' do
      lambda do
        @eq1.matches?('bgo').should be_false
      end.should raise_error(AclArgumentError)

      lambda do
        @eq2.matches?('chargem').should be_false
      end.should raise_error(AclArgumentError)

      lambda do
        @any.matches?('hogehoge')
      end.should raise_error(AclArgumentError)
    end

    it 'should be raise error by udp protocol name' do
      lambda do
        @any.matches?('biff')
      end.should raise_error(AclArgumentError)
    end
  end
end

describe AceUdpPortSpec do
  describe '#==' do
    before(:all) do
      @p1a = AceUdpProtoSpec.new(number: 512)
      @p1b = AceUdpProtoSpec.new(name: 'biff')
      @p2  = AceUdpProtoSpec.new(number: 688)
      @p3  = AceUdpProtoSpec.new(number: 1022)
    end

    it 'should be true when same operator, same protocol' do
      a = AceUdpPortSpec.new(
        operator: 'range', begin_port: @p1a, end_port: @p2
      )
      b = AceUdpPortSpec.new(
        operator: 'range', begin_port: @p1b, end_port: @p2
      )
      (a == b).should be_true
    end

    it 'should be false when different protocol' do
      a = AceUdpPortSpec.new(
        operator: 'range', begin_port: @p1a, end_port: @p2
      )
      b = AceUdpPortSpec.new(
        operator: 'range', begin_port: @p1b, end_port: @p3
      )
      (a == b).should be_false
    end

    it 'should be false when different operator' do
      a = AceUdpPortSpec.new(
        operator: 'range', begin_port: @p1a, end_port: @p2
      )
      b = AceUdpPortSpec.new(
        operator: 'gt', begin_port: @p1b
      )
      (a == b).should be_false
    end
  end

  describe '#matches? by class variation' do
    before(:all) do
      @p1 = AceUdpProtoSpec.new(name: 'biff')
      @eq1 = AceUdpPortSpec.new(
        operator: 'eq', port: @p1
      )
      @p2 = AceUdpProtoSpec.new(number: 9)
      @eq2 = AceUdpPortSpec.new(
        operator: 'eq', port: @p2
      )
      @any = AceUdpPortSpec.new(
        operator: 'any'
      )
    end

    it 'should be true by correct String arg' do
      @eq1.matches?(512).should be_true
      @eq1.matches?('512').should be_true
      @eq1.matches?('biff').should be_true

      @eq2.matches?(9).should be_true
      @eq2.matches?('9').should be_true
      @eq2.matches?('discard').should be_true

      @any.matches?(3).should be_true
      @any.matches?('55').should be_true
      @any.matches?('snmp').should be_true
    end

    it 'should be false by wrong String arg' do
      @eq1.matches?(513).should be_false
      @eq1.matches?('513').should be_false

      @eq2.matches?(10).should be_false
      @eq2.matches?('8').should be_false
    end

    it 'should be raise error by unknown arg' do
      lambda do
        @eq1.matches?('bifff').should be_false
      end.should raise_error(AclArgumentError)

      lambda do
        @eq2.matches?('dixcard').should be_false
      end.should raise_error(AclArgumentError)

      lambda do
        @any.matches?('hogehoge')
      end.should raise_error(AclArgumentError)
    end

    it 'should be raise error by udp protocol name' do
      lambda do
        @any.matches?('www')
      end.should raise_error(AclArgumentError)
    end
  end
end
