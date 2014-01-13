# -*- coding: utf-8 -*-
require 'spec_helper'

describe AcePortSpec do
  describe '#new' do
    it 'shoud be error with unknown operator' do
      lambda do
        AcePortSpec.new(
          operator: 'equal',
          port1: 443
        )
      end.should raise_error(AclArgumentError)
    end

    it 'should be error with invalid ports' do
      lambda do
        AcePortSpec.new(
          operator: 'range',
          port1: 443,
          port2: 139
        )
      end.should raise_error(AclArgumentError)
    end
  end

  describe '#to_s' do
    before do
      @p1 = AceTcpProtoSpec.new(number: 22)
      @p2 = AceTcpProtoSpec.new(number: 80)
    end

    context 'Normal case' do
      it 'should be "eq 22"' do
        p = AcePortSpec.new(
          operator: 'eq', port1: @p1
        )
        p.to_s.should be_aclstr('eq 22')
      end

      it 'should be "lt www"' do
        p = AcePortSpec.new(
          operator: 'lt', port1: @p2
        )
        p.to_s.should be_aclstr('lt www')
      end

      it 'should be "gt www"' do
        p = AcePortSpec.new(
          operator: 'gt', port1: @p2
        )
        p.to_s.should be_aclstr('gt www')
      end

      it 'should be "range 22 www"' do
        p = AcePortSpec.new(
          operator: 'range',
          port1: @p1, port2: @p2
        )
        p.to_s.should be_aclstr('range 22 www')
      end

      it 'should be empty when any port' do
        p = AcePortSpec.new(
          operator: 'any',
          port1: @p1, port2: @p2
        )
        p.to_s.should be_empty
      end

    end
    context 'Argument error case' do
      it 'raise error when not specified operator' do
        lambda do
          AcePortSpec.new(
            port2: @p1
          )
        end.should raise_error(AclArgumentError)
      end

      it 'raise error when not specified port1' do
        lambda do
          AcePortSpec.new(
            operator: 'eq',
            port2: @p1
          )
        end.should raise_error(AclArgumentError)
      end

      it 'raise error when wrong port sequence' do
        lambda do
          AcePortSpec.new(
            operator: 'range',
            port1: @p2, port2: @p1
          )
        end.should raise_error(AclArgumentError)
      end
    end
  end

  describe '#matches?' do
    before do
      @p1 = AceTcpProtoSpec.new(number: 22)
      @p2 = AceTcpProtoSpec.new(number: 32_768)

      @any = AcePortSpec.new(
        operator: 'any'
      )
      @eq1 = AcePortSpec.new(
        operator: 'eq', port1: @p1
      )
      @neq1 = AcePortSpec.new(
        operator: 'neq', port1: @p1
      )
      @lt1 = AcePortSpec.new(
        operator: 'lt', port1: @p1
      )
      @gt1 = AcePortSpec.new(
        operator: 'gt', port1: @p1
      )
      @range = AcePortSpec.new(
        operator: 'range',
        port1: @p1, port2: @p2
      )
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
