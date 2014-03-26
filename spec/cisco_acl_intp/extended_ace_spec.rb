# -*- coding: utf-8 -*-
require 'spec_helper'

def _build_taget(opts)
  ExtendedAce.new(
    action: (opts[:target] || 'permit'),
    protocol: (opts[:protocol] || 'tcp'),
    src: AceSrcDstSpec.new(
      ipaddr: opts[:src_ip], netmask: 32,
      operator: :eq, port: AceTcpProtoSpec.new(opts[:src_port])
    ),
    dst: AceSrcDstSpec.new(
      ipaddr: opts[:dst_ip], netmask: 32,
      operator: :eq, port: AceTcpProtoSpec.new(opts[:dst_port])
    )
  )
end

describe ExtendedAce do
  describe '#to_s' do
    context 'Normal case' do
      before do
        @src = AceSrcDstSpec.new(
          ipaddr: '192.168.15.15',
          wildcard: '0.0.7.6'
        )
        @dst = AceSrcDstSpec.new(
          ipaddr: '192.168.30.3',
          wildcard: '0.0.0.0',
          operator: 'range',
          begin_port: AceTcpProtoSpec.new(1_024),
          end_port: AceTcpProtoSpec.new(65_535)
        )
      end

      it 'should be protocol tcp, action permit' do
        ea = ExtendedAce.new(
          action: 'permit',
          protocol: 'tcp',
          src: @src,
          dst: @dst
        )
        ea.to_s.should be_aclstr(
          'permit tcp 192.168.8.9 0.0.7.6 host 192.168.30.3 range 1024 65535'
        )
      end

      it 'should be protocol tcp, action deny' do
        ea = ExtendedAce.new(
          action: 'deny',
          protocol: 'tcp',
          src: @src,
          dst: @dst
        )
        ea.to_s.should be_aclstr(
          'deny tcp 192.168.8.9 0.0.7.6 host 192.168.30.3 range 1024 65535'
        )
      end

    end

    context 'Argument error case' do
      before do
        @src = AceSrcDstSpec.new(
          ipaddr: '192.168.15.15',
          wildcard: '0.0.7.6'
        )
        @dst = AceSrcDstSpec.new(
          ipaddr: '192.168.30.3',
          wildcard: '0.0.0.0',
          operator: 'range',
          begin_port: AceTcpProtoSpec.new(1_024),
          end_port: AceTcpProtoSpec.new(65_535)
        )
      end

      it 'should be rased exception when :action not specified' do
        lambda do
          ExtendedAce.new(
            protocol: 'tcp',
            src: @src,
            dst: @dst
          )
        end.should raise_error(AclArgumentError)
      end

      it 'should be rased exception when :protocol not specified' do
        lambda do
          ExtendedAce.new(
            action: 'deny',
            src: @src,
            dst: @dst
          )
        end.should raise_error(AclArgumentError)
      end

      it 'should be rased exception when :src not specified' do
        lambda do
          ExtendedAce.new(
            action: 'deny',
            protocol: 'tcp',
            dst: @dst
          )
        end.should raise_error(AclArgumentError)
      end

      it 'should be rased exception when :dst not specified' do
        lambda do
          ExtendedAce.new(
            action: 'deny',
            protocol: 'tcp',
            src: @src
          )
        end.should raise_error(AclArgumentError)
      end

    end
  end

  describe '#contains?' do
    context 'tcp src/dst ip/port full spec test' do
      before do
        src = AceSrcDstSpec.new(
          ipaddr: '192.168.15.15',
          wildcard: '0.0.7.6',
          operator: 'gt',
          port: AceTcpProtoSpec.new(32_767)
        )
        dst = AceSrcDstSpec.new(
          ipaddr: '192.168.30.3',
          wildcard: '0.0.0.0',
          operator: 'range',
          begin_port: AceTcpProtoSpec.new(1_024),
          end_port: AceTcpProtoSpec.new(65_535)
        )
        @ea = ExtendedAce.new(
          action: 'permit',
          protocol: 'tcp',
          src: src,
          dst: dst
        )
      end # before

      ## generate test pattern data
      data_table = {
        protocol_match: 'tcp',
        protocol_unmatch: 'udp',
        src_ip_match: '192.168.9.11',
        src_ip_unmatch: '192.168.9.12',
        src_port_match: 32_768,
        src_port_unmatch: 8_080,
        dst_ip_match: '192.168.30.3',
        dst_ip_unmatch: '192.168.30.4',
        dst_port_match: 3_366,
        dst_port_unmatch: 100
      }

      bit = 5
      test_data = [
        :dst_port,
        :dst_ip,
        :src_port,
        :src_ip,
        :protocol
      ]

      tests = []
      (0..(2**bit - 1)).each do |num|
        opts = {}
        flag = 1
        (0...bit).each do |b|
          pstr = ((num & flag) == 0 ? '_match' : '_unmatch')
          key = test_data[b].to_s.concat(pstr)
          opts[test_data[b]] = data_table[key.to_sym]
          flag = flag << 1
        end
        tests.push(
          opts: opts,
          res: num > 0 ? false : true
        )
      end

      tests.each do |each|
        # test params
        eres = each[:res]
        eopts = each[:opts]
        teststr = [
          "should be #{eres}",
          "when #{eopts[:protocol]};",
          "#{eopts[:src_ip]}:#{eopts[:src_port]} >",
          "#{eopts[:dst_ip]}:#{eopts[:dst_port]}"
        ].join(' ')
        # run test
        it teststr do
          if eres
            @ea.contains?(_build_taget(eopts)).should be_true
          else
            @ea.contains?(_build_taget(eopts)).should be_false
          end
        end # it
      end # tests.each

    end # context full spec test

    context 'ANY ip/port port exists case' do
      before do
        ip_any = AceIpSpec.new(
          ipaddr: '0.0.0.0', wildcard: '255.255.255.255'
        )
        port_any = AcePortSpec.new(operator: 'any')
        src_ip = AceIpSpec.new(
          ipaddr: '192.168.15.15', wildcard: '0.0.7.6'
        )
        src_port = AcePortSpec.new(
          operator: 'gt', port: AceTcpProtoSpec.new(32_767)
        )

        dst_ip = AceIpSpec.new(
          ipaddr: '192.168.30.3', wildcard: '0.0.0.0'
        )
        dst_port = AcePortSpec.new(
          operator: 'range',
          begin_port: AceTcpProtoSpec.new(1_024),
          end_port: AceTcpProtoSpec.new(65_535)
        )

        @src0 = AceSrcDstSpec.new(ip_spec: src_ip, port_spec: src_port)
        @src1 = AceSrcDstSpec.new(ip_spec: ip_any, port_spec: src_port)
        @src2 = AceSrcDstSpec.new(ip_spec: src_ip, port_spec: port_any)
        @dst0 = AceSrcDstSpec.new(ip_spec: dst_ip, port_spec: dst_port)
        @dst1 = AceSrcDstSpec.new(ip_spec: ip_any, port_spec: dst_port)
        @dst2 = AceSrcDstSpec.new(ip_spec: dst_ip, port_spec: port_any)

        @src_ip_match = '192.168.9.11'
        @src_ip_unmatch = '192.168.9.12'
        @src_port_match = 32_768
        @src_port_unmatch = 8_080
        @dst_ip_match = '192.168.30.3'
        @dst_ip_unmatch = '192.168.30.4'
        @dst_port_match = 3_366
        @dst_port_unmatch = 100
      end

      it 'should be true when any source ip' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src1, dst: @dst0
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_match
        )).should be_true
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_unmatch, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match,   dst_port: @dst_port_match
        )).should be_true
      end

      it 'should be false when any source ip and unmatch port' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src1, dst: @dst0
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_unmatch,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_match
        )).should be_false
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_unmatch, src_port: @src_port_unmatch,
            dst_operator: :eq,
            dst_ip: @dst_ip_match,   dst_port: @dst_port_match
        )).should be_false
      end

      it 'should be true when any source port' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src2, dst: @dst0
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_match
        )).should be_true
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_unmatch,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_match
        )).should be_true
      end

      it 'should be false when any source port and unmatch ip' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src2, dst: @dst0
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_unmatch, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match,   dst_port: @dst_port_match
        )).should be_false
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_unmatch, src_port: @src_port_unmatch,
            dst_operator: :eq,
            dst_ip: @dst_ip_match,   dst_port: @dst_port_match
        )).should be_false
      end

      it 'should be true when any destination ip' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src0, dst: @dst1
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_match
        )).should be_true
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match,   src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_unmatch, dst_port: @dst_port_match
        )).should be_true
      end

      it 'should be false when any destination ip and unmatch port' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src0, dst: @dst1
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_unmatch
        )).should be_false
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match,   src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_unmatch, dst_port: @dst_port_unmatch
        )).should be_false
      end

      it 'should be true when any destination port' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src0, dst: @dst2
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_match
        )).should be_true
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match, src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_match, dst_port: @dst_port_unmatch
        )).should be_true
      end

      it 'should be false when any destination port and unmatch ip' do
        ea = ExtendedAce.new(
          action: 'permit', protocol: 'tcp', src: @src0, dst: @dst2
        )
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match,   src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_unmatch, dst_port: @dst_port_match
        )).should be_false
        ea.contains?(_build_taget(
            protocol: 'tcp',
            src_operator: :eq,
            src_ip: @src_ip_match,   src_port: @src_port_match,
            dst_operator: :eq,
            dst_ip: @dst_ip_unmatch, dst_port: @dst_port_unmatch
        )).should be_false
      end
    end # context exists any ip/port
  end # describe contains?
end # describe ExtendedAce

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
