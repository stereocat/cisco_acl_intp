# -*- coding: utf-8 -*-
require 'cisco_acl_intp/extended_ace'

module CiscoAclIntp
  # Extended Ace utilities for ace search
  module AceSearchUtility
    # Select protocol spec class for tcp/udp.
    # @param [String] proto Protocol name.
    # @return [Class] Class name.
    def select_proto_class(proto)
      case proto
      when 'tcp'
        AceTcpProtoSpec
      when 'udp'
        AceUdpProtoSpec
      end
    end

    # @param [String] proto Protocol name.
    # @param [Integer, String] port Port No./Name.
    # @return [AceTcpProtoSpec, AceUdpProtoSpec] TCP/UDP port object.
    def generate_port_obj(proto, port = nil)
      port.nil? ? nil : select_proto_class(proto).new(port)
    end

    # Generate port spec by protocol
    # @param [String] proto Protocol name.
    # @param [String, Symbol] opr Port operator.
    # @param [Integer, String] begin_port Port No./Name.
    # @param [Integer, String] end_port Port No./Name.
    # @return [AcePortSpec] Port spec.
    def port_spec_by_protocol(proto, opr, begin_port = nil, end_port = nil)
      if opr.nil?
        AcePortSpec.new(operator: :any) # any
      else
        AcePortSpec.new(
          operator: opr,
          begin_port: generate_port_obj(proto, begin_port),
          end_port: generate_port_obj(proto, end_port)
        )
      end
    end

    # Generate Src/Dst search condition
    # @param [AceIpProtoSpec] proto IP protocol info
    # @param [String] ip IP address info
    # @param [String, Symbol] opr Port operator
    # @param [Integer, String] begin_port Port No./Name.
    # @param [Integer, String] end_port Port No./Name.
    def srcdst_condition(proto, ip, opr, begin_port = nil, end_port = nil)
      case proto.name
      when 'tcp', 'udp'
        AceSrcDstSpec.new(
          ipaddr: ip,
          port_spec: port_spec_by_protocol(
            proto.name, opr, begin_port, end_port
          )
        )
      else
        # if L3 protocol is not tcp/udp, it did not need port condition
        AceSrcDstSpec.new(ipaddr: ip)
      end
    end

    # Generate hash key to slice
    # @param [Symbol] pt Prefix of key
    # @param [Symbol] key Postfix of key
    # @return [Symbol]
    def ptkey(pt, key)
      [pt.to_s, key.to_s].join('_').intern
    end

    # Generate list of values sliced hash (args of srcdst_condition)
    # @param [AceIpProtoSpec] proto_cond IP protocol condition
    # @param [Symbol] pt Prefix of key
    # @param [Hash] opts Option hash for slice
    def slice_contains_opts(proto_cond, pt, opts)
      [
        proto_cond,
        opts[ptkey(pt, :ip)],
        opts[ptkey(pt, :operator)],
        (opts[ptkey(pt, :port)] || opts[ptkey(pt, :begin_port)]),
        opts[ptkey(pt, :end_port)]
      ]
    end

    # Generate ACE components
    # @param [Hash] opts Options (target packet info)
    # @see options is same as ExtendedAce#contains?
    # @return [Array<AceIpProtoSpec, AceSrcDstSpec, AceSrcDstSpec>]
    def search_conditions(opts)
      proto_cond = AceIpProtoSpec.new(opts[:protocol])
      [
        proto_cond,
        srcdst_condition(*slice_contains_opts(proto_cond, :src, opts)),
        srcdst_condition(*slice_contains_opts(proto_cond, :dst, opts))
      ]
    end

    # Generate ACE search(contains?) conditions
    # @param [Hash] opts Options (target packet info)
    # @see options is same as ExtendedAce#contains?
    # @return [ExtendedAce]
    def target_ace(opts)
      (proto_cond, src_cond, dst_cond) = search_conditions(opts)
      ExtendedAce.new(
        action: 'permit', protocol: proto_cond.name,
        src: src_cond, dst: dst_cond
      )
    end
  end # module ExtendedAceSearchUtility
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
