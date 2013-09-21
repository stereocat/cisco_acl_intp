# -*- coding: utf-8 -*-

require 'spec_helper'

include CiscoAclIntp
AclContainerBase::disable_color

describe AceSrcDstSpec do
  describe "#to_s" do
    context 'Normal case' do
      before do
        @p1 = AceTcpProtoSpec.new( :number => 80 )
      end

      it 'should be "192.168.3.0 0.0.0.127" without L4 port' do
        sds = AceSrcDstSpec.new(
          :ipaddr => '192.168.3.3', :wildcard => '0.0.0.127'
        )
        sds.to_s.should be_aclstr("192.168.3.0 0.0.0.127")
      end

      it 'should be "192.168.3.0 eq www" with L4 port' do
        sds = AceSrcDstSpec.new(
          :ipaddr => '192.168.3.3', :wildcard => '0.0.0.127',
          :operator => 'eq', :port1 => @p1
        )
        sds.to_s.should be_aclstr("192.168.3.0 0.0.0.127 eq www")
      end
    end

    context 'Argument error case' do

      it 'should be raise exception when :ipaddr not specified' do
        lambda {
          sds = AceSrcDstSpec.new(
            :wildcard => '0.0.0.127'
          )
        }.should raise_error(AclArgumentError)
      end

      ## TBD, エラー処理はもうちょっとちゃんとかく必要がある
    end
  end

  describe "#matches?" do

    context 'with port unary operator: eq/neq/gt/lt' do
      before(:each) do
        ipaddr = AceIpSpec.new(
          :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6'
        )
        @p1 = AceTcpProtoSpec.new( :number => 80 )
        @sds0 = AceSrcDstSpec.new(
          :ip_spec => ipaddr
        )
        @sds1 = AceSrcDstSpec.new(
          :ip_spec => ipaddr, :operator => 'eq', :port1 => @p1
        )
        @sds2 = AceSrcDstSpec.new(
          :ip_spec => ipaddr, :operator => 'neq', :port1 => @p1
        )
        @sds3 = AceSrcDstSpec.new(
          :ip_spec => ipaddr, :operator => 'lt', :port1 => @p1
        )
        @sds4 = AceSrcDstSpec.new(
          :ip_spec => ipaddr, :operator => 'gt', :port1 => @p1
        )
        @ip_match = '192.168.9.11'
        @ip_unmatch = '192.168.9.12'
        @p1_match = 80
        @p1_unmatch = 88
        @p1_lower = 22
        @p1_higher = 6633
      end

      context "with IP only entry" do
        it 'should be true, when match ip and "any" port' do
          @sds0.matches?(@ip_match, @p1_match).should be_true
          @sds0.matches?(@ip_match, @p1_unmatch).should be_true
          @sds0.matches?(@ip_match, @p1_lower).should be_true
          @sds0.matches?(@ip_match, @p1_higher).should be_true
        end

        it 'should be false, when unmatch ip and "any" port' do
          @sds0.matches?(@ip_unmatch, @p1_match).should be_false
          @sds0.matches?(@ip_unmatch, @p1_unmatch).should be_false
          @sds0.matches?(@ip_unmatch, @p1_lower).should be_false
          @sds0.matches?(@ip_unmatch, @p1_higher).should be_false
        end
      end

      context "eq" do
        it 'should be true, with match ip match eq port' do
          @sds1.matches?(@ip_match, @p1_match).should be_true
        end

        it 'should be false, with match ip and unmatch eq port' do
          @sds1.matches?(@ip_match, @p1_unmatch).should be_false
        end

        it 'should be false, with unmatch ip and match eq port' do
          @sds1.matches?(@ip_unmatch, @p1_match).should be_false
        end

        it 'should be false, with unmatch ip and unmatch eq port' do
          @sds1.matches?(@ip_unmatch, @p1_unmatch).should be_false
        end
      end

      context "neq" do
        it 'should be false, with match ip match eq port' do
          @sds2.matches?(@ip_match, @p1_match).should be_false
        end

        it 'should be true, with match ip and unmatch eq port' do
          @sds2.matches?(@ip_match, @p1_unmatch).should be_true
        end

        it 'should be false, with unmatch ip and match eq port' do
          @sds2.matches?(@ip_unmatch, @p1_match).should be_false
        end

        it 'should be false, with unmatch ip and unmatch eq port' do
          @sds2.matches?(@ip_unmatch, @p1_unmatch).should be_false
        end
      end

      context "lt" do
        it 'should be true, with match ip lower eq port' do
          @sds3.matches?(@ip_match, @p1_lower).should be_true
        end

        it 'should be false, with match ip and higher eq port' do
          @sds3.matches?(@ip_match, @p1_higher).should be_false
        end

        it 'should be false, with unmatch ip and loser eq port' do
          @sds3.matches?(@ip_unmatch, @p1_lower).should be_false
        end

        it 'should be false, with unmatch ip and higher eq port' do
          @sds3.matches?(@ip_unmatch, @p1_higher).should be_false
        end
      end

      context "gt" do
        it 'should be false, with match ip lower eq port' do
          @sds4.matches?(@ip_match, @p1_lower).should be_false
        end

        it 'should be true, with match ip and higher eq port' do
          @sds4.matches?(@ip_match, @p1_higher).should be_true
        end

        it 'should be false, with unmatch ip and loser eq port' do
          @sds4.matches?(@ip_unmatch, @p1_lower).should be_false
        end

        it 'should be false, with unmatch ip and higher eq port' do
          @sds4.matches?(@ip_unmatch, @p1_higher).should be_false
        end
      end

    end

    context 'with operator: range' do
      before(:each) do
        p1 = AceTcpProtoSpec.new( :number => 80 )
        p2 = AceTcpProtoSpec.new( :number => 1023 )
        @sds = AceSrcDstSpec.new(
          :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6',
          :operator => 'range',
          :port1 => p1, :port2 => p2
        )
        @ip_match = '192.168.9.11'
        @ip_unmatch = '192.168.9.12'
        @p_in = 512
        @p_out_lower = 23
        @p_out_higher = 6633
      end

      it 'should be true, with match ip in range port' do
        @sds.matches?(@ip_match, @p_in).should be_true
      end

      it 'should be false, with match ip and out of range port (lower)' do
        @sds.matches?(@ip_match, @p_out_lower).should be_false
      end

      it 'should be false, with match ip and out of range port (higher)' do
        @sds.matches?(@ip_match, @p_out_higher).should be_false
      end

      it 'should be false, with unmatch ip match in range port' do
        @sds.matches?(@ip_unmatch, @p_in).should be_false
      end

      it 'should be false, with unmatch ip and out of range port (lower)' do
        @sds.matches?(@ip_unmatch, @p_out_lower).should be_false
      end

      it 'should be false, with unmatch ip and out of range port (higher)' do
        @sds.matches?(@ip_unmatch, @p_out_higher).should be_false
      end
    end

    context 'with ip or port any' do
      before do
        ip_any = AceIpSpec.new(
          :ipaddr => '0.0.0.0', :wildcard => '255.255.255.255'
        )
        port_any = AcePortSpec.new( :operator => 'any' )
        ip1 = AceIpSpec.new(
          :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6'
        )
        port1 = AcePortSpec.new(
          :operator => 'range',
          :port1 => AceTcpProtoSpec.new( :number => 80 ),
          :port2 => AceTcpProtoSpec.new( :number => 1023 )
        )
        @sds1 = AceSrcDstSpec.new( :ip_spec => ip_any, :port_spec => port1 )
        @sds2 = AceSrcDstSpec.new( :ip_spec => ip1,    :port_spec => port_any )
        @sds3 = AceSrcDstSpec.new( :ip_spec => ip_any, :port_spec => port_any )
        @ip_match = '192.168.9.11'
        @ip_unmatch = '192.168.9.12'
        @p_match = 512
        @p_unmatch = 6633
      end

      it 'should be true, for any ip' do
        @sds1.matches?(@ip_match, @p_match).should be_true
        @sds1.matches?(@ip_unmatch, @p_match).should be_true
      end

      it 'should be false, for any ip with unmatch port' do
        @sds1.matches?(@ip_match, @p_unmatch).should be_false
        @sds1.matches?(@ip_unmatch, @p_unmatch).should be_false
      end

      it 'should be true, for any port' do
        @sds2.matches?(@ip_match, @p_match).should be_true
        @sds2.matches?(@ip_match, @p_unmatch).should be_true
      end

      it 'should be false, for any port with unmatch ip' do
        @sds2.matches?(@ip_unmatch, @p_match).should be_false
        @sds2.matches?(@ip_unmatch, @p_unmatch).should be_false
      end

      it 'should be true, for any ip and any port' do
        @sds3.matches?(@ip_match, @p_match).should be_true
        @sds3.matches?(@ip_match, @p_unmatch).should be_true
        @sds3.matches?(@ip_unmatch, @p_match).should be_true
        @sds3.matches?(@ip_unmatch, @p_unmatch).should be_true
      end

    end

  end # describe matches?

end # describe AceSrcDstSpec
