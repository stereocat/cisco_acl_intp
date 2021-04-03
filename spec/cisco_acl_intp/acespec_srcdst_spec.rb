# frozen_string_literal: true

require 'spec_helper'

describe AceSrcDstSpec do
  describe '#==' do
    before(:all) do
      @sds1 = AceSrcDstSpec.new(
        ipaddr: '192.168.4.2', wildcard: '0.0.0.255',
        operator: :eq, port: AceTcpProtoSpec.new(88)
      )
      @sds2 = AceSrcDstSpec.new(
        ipaddr: '192.168.4.2', netmask: 24,
        operator: 'eq', port: AceTcpProtoSpec.new('88')
      )
      @sds3 = AceSrcDstSpec.new(
        ipaddr: '192.168.4.2', wildcard: '0.0.0.255',
        operator: 'lt', port: AceTcpProtoSpec.new(88)
      )
      @sds4 = AceSrcDstSpec.new(
        ipaddr: '192.168.4.3', wildcard: '0.0.0.255',
        operator: 'eq', port: AceTcpProtoSpec.new(88)
      )
    end

    it 'should be true when same ip/netmask/wildcard' do
      expect(@sds1 == @sds2).to be_truthy
    end

    it 'should be false when different operator' do
      expect(@sds1 == @sds3).to be_falsey
    end

    it 'should be false when different ip' do
      expect(@sds1 == @sds4).to be_falsey
    end
  end

  describe '#to_s' do
    context 'Normal case' do
      it 'should be "192.168.3.0 0.0.0.127" without L4 port' do
        sds = AceSrcDstSpec.new(
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127'
        )
        expect(sds.to_s).to be_aclstr('192.168.3.0 0.0.0.127')
      end

      it 'should be "192.168.3.0 eq www" with L4 port' do
        sds = AceSrcDstSpec.new(
          ipaddr: '192.168.3.3',
          wildcard: '0.0.0.127',
          operator: 'eq',
          port: AceTcpProtoSpec.new(80)
        )
        expect(sds.to_s).to be_aclstr('192.168.3.0 0.0.0.127 eq www')
      end
    end

    context 'Argument error case' do
      it 'should be raise exception when :ipaddr not specified' do
        expect do
          AceSrcDstSpec.new(
            wildcard: '0.0.0.127'
          )
        end.to raise_error(AclArgumentError)
      end
      ## TBD, error handling must be written in detail
    end
  end

  describe '#contains?' do
    def _srcdst(ip, opr, port)
      ip_spec = AceIpSpec.new(ipaddr: ip)
      port_spec = AceTcpProtoSpec.new(port)
      AceSrcDstSpec.new(ip_spec: ip_spec, operator: opr, port: port_spec)
    end

    context 'port containing check' do
      before(:all) do
        ipaddr = AceIpSpec.new(ipaddr: '192.168.15.15', wildcard: '0.0.7.6')
        @p1 = AceTcpProtoSpec.new(80)
        @sds0 = AceSrcDstSpec.new(ip_spec: ipaddr)
        @sds1 = AceSrcDstSpec.new(ip_spec: ipaddr, operator: :lt, port: @p1)

        @ip_match = '192.168.9.11'
        @ip_unmatch = '192.168.9.12'
        @p1_match = 80
        @p1_unmatch = 88
        @p1_lower = 22
        @p1_higher = 6633
      end

      it 'should be true when match ip and ANY port' do
        expect(
          @sds0.contains?(_srcdst(@ip_match, :eq, @p1_match))
        ).to be_truthy
        expect(
          @sds0.contains?(_srcdst(@ip_match, :eq, @p1_unmatch))
        ).to be_truthy
      end

      it 'should be false when unmatch ip and ANY port' do
        expect(
          @sds0.contains?(_srcdst(@ip_unmatch, :eq, @p1_match))
        ).to be_falsey
        expect(
          @sds0.contains?(_srcdst(@ip_unmatch, :eq, @p1_unmatch))
        ).to be_falsey
      end

      it 'should be true when match ip and contained port set' do
        expect(
          @sds1.contains?(_srcdst(@ip_match, :eq, @p1_lower))
        ).to be_truthy
        expect(
          @sds1.contains?(_srcdst(@ip_match, :lt, @p1_match))
        ).to be_truthy
      end

      it 'should be false when unmatch ip and contained port set' do
        expect(
          @sds1.contains?(_srcdst(@ip_unmatch, :eq, @p1_lower))
        ).to be_falsey
        expect(
          @sds1.contains?(_srcdst(@ip_unmatch, :lt, @p1_match))
        ).to be_falsey
      end

      it 'should be false when match ip and not-contained port set' do
        expect(
          @sds1.contains?(_srcdst(@ip_match, :eq, @p1_match))
        ).to be_falsey
        expect(
          @sds1.contains?(_srcdst(@ip_match, :lt, @p1_higher))
        ).to be_falsey
      end
    end

    context 'subnet containing check' do
      before do
        ipaddr = AceIpSpec.new(ipaddr: '192.168.15.15', wildcard: '0.0.0.127')
        @p1 = AceTcpProtoSpec.new('www')
        @sds0 = AceSrcDstSpec.new(ip_spec: ipaddr)
        @sds1 = AceSrcDstSpec.new(ip_spec: ipaddr, operator: 'eq', port: @p1)

        @ip_contained1 = '192.168.15.16/26'
        @ip_not_contained1 = '192.168.15.0/24'
        @ip_contained2 = '192.168.15.16/255.255.255.192'
        @ip_not_contained2 = '192.168.15.0/255.255.255.0'
        @p1_match = 80
        @ip_error1 = '192.168.15.16 mask 26'
        # @ip_error2 = '192.168.15.16 255.255.255.192'
      end

      it 'should be true when contained (length)' do
        expect(
          @sds0.contains?(_srcdst(@ip_contained1, :eq, @p1_match))
        ).to be_truthy
        expect(
          @sds1.contains?(_srcdst(@ip_contained1, :eq, @p1_match))
        ).to be_truthy
      end

      it 'should be true when contained (bitmask)' do
        expect(
          @sds0.contains?(_srcdst(@ip_contained2, :eq, @p1_match))
        ).to be_truthy
        expect(
          @sds1.contains?(_srcdst(@ip_contained2, :eq, @p1_match))
        ).to be_truthy
      end

      it 'should be false when not contained (length)' do
        expect(
          @sds0.contains?(_srcdst(@ip_not_contained1, :eq, @p1_match))
        ).to be_falsey
        expect(
          @sds1.contains?(_srcdst(@ip_not_contained1, :eq, @p1_match))
        ).to be_falsey
      end

      it 'should be false when not contained (bitmask)' do
        expect(
          @sds0.contains?(_srcdst(@ip_not_contained2, :eq, @p1_match))
        ).to be_falsey
        expect(
          @sds1.contains?(_srcdst(@ip_not_contained2, :eq, @p1_match))
        ).to be_falsey
      end

      it 'should be raised error when invalid subnet notation' do
        expect do
          @sds0.contains?(_srcdst(@ip_error1, :eq, @p1_match))
        end.to raise_error(NetAddr::ValidationError)

        expect do
          @sds1.contains?(_srcdst(@ip_error1, :eq, @p1_match))
        end.to raise_error(NetAddr::ValidationError)

        # lambda do
        # @sds0.contains?(_srcdst(@ip_error2, :eq, @p1_match)).should be_false
        # end.should raise_error(NetAddr::ValidationError)

        # lambda do
        # @sds1.contains?(_srcdst(@ip_error2, :eq, @p1_match)).should be_false
        # end.should raise_error(NetAddr::ValidationError)
      end
    end

    context 'with operator: range' do
      before(:each) do
        p1 = AceTcpProtoSpec.new(80)
        p2 = AceTcpProtoSpec.new(1023)
        @sds = AceSrcDstSpec.new(
          ipaddr: '192.168.15.15',
          wildcard: '0.0.7.6',
          operator: 'range',
          begin_port: p1,
          end_port: p2
        )
        @ip_match = '192.168.9.11'
        @ip_unmatch = '192.168.9.12'
        @p_in = 512
        @p_out_lower = 23
        @p_out_higher = 6633
      end

      it 'should be true, with match ip in range port' do
        expect(
          @sds.contains?(_srcdst(@ip_match, :eq, @p_in))
        ).to be_truthy
      end

      it 'should be false, with match ip and out of range port' do
        expect(
          @sds.contains?(_srcdst(@ip_match, :eq, @p_out_lower))
        ).to be_falsey
        expect(
          @sds.contains?(_srcdst(@ip_match, :eq, @p_out_higher))
        ).to be_falsey
      end

      it 'should be false, with unmatch ip match in range port' do
        expect(
          @sds.contains?(_srcdst(@ip_unmatch, :eq, @p_in))
        ).to be_falsey
      end
    end

    context 'with ip or port any' do
      before do
        ip_any = AceIpSpec.new(
          ipaddr: '0.0.0.0',
          wildcard: '255.255.255.255'
        )
        port_any = AcePortSpec.new(
          operator: 'any'
        )
        ip1 = AceIpSpec.new(
          ipaddr: '192.168.15.15',
          wildcard: '0.0.7.6'
        )
        port_range = AcePortSpec.new(
          operator: 'range',
          begin_port: AceTcpProtoSpec.new(80),
          end_port: AceTcpProtoSpec.new(1023)
        )
        @sds1 = AceSrcDstSpec.new(
          ip_spec: ip_any,
          port_spec: port_range
        )
        @sds2 = AceSrcDstSpec.new(
          ip_spec: ip1,
          port_spec: port_any
        )
        @sds3 = AceSrcDstSpec.new(
          ip_spec: ip_any,
          port_spec: port_any
        )
        @ip_match = '192.168.9.11'
        @ip_unmatch = '192.168.9.12'
        @p_match = 512
        @p_unmatch = 6633
      end

      it 'should be true, for any ip' do
        expect(
          @sds1.contains?(_srcdst(@ip_match, :eq, @p_match))
        ).to be_truthy
        expect(
          @sds1.contains?(_srcdst(@ip_unmatch, :eq, @p_match))
        ).to be_truthy
      end

      it 'should be false, for any ip with unmatch port' do
        expect(
          @sds1.contains?(_srcdst(@ip_match, :eq, @p_unmatch))
        ).to be_falsey
        expect(
          @sds1.contains?(_srcdst(@ip_unmatch, :eq, @p_unmatch))
        ).to be_falsey
      end

      it 'should be true, for any port' do
        expect(
          @sds2.contains?(_srcdst(@ip_match, :eq, @p_match))
        ).to be_truthy
        expect(
          @sds2.contains?(_srcdst(@ip_match, :eq, @p_unmatch))
        ).to be_truthy
      end

      it 'should be false, for any port with unmatch ip' do
        expect(
          @sds2.contains?(_srcdst(@ip_unmatch, :eq, @p_match))
        ).to be_falsey
        expect(
          @sds2.contains?(_srcdst(@ip_unmatch, :eq, @p_unmatch))
        ).to be_falsey
      end

      it 'should be true, for any ip and any port' do
        expect(
          @sds3.contains?(_srcdst(@ip_match, :eq, @p_match))
        ).to be_truthy
        expect(
          @sds3.contains?(_srcdst(@ip_match, :eq, @p_unmatch))
        ).to be_truthy
        expect(
          @sds3.contains?(_srcdst(@ip_unmatch, :eq, @p_match))
        ).to be_truthy
        expect(
          @sds3.contains?(_srcdst(@ip_unmatch, :eq, @p_unmatch))
        ).to be_truthy
      end
    end
  end
end
