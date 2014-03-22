# -*- coding: utf-8 -*-
require 'cisco_acl_intp/standard_ace'

module CiscoAclIntp
  # Extended Ace utilities for ace search
  module ExtendedAceSearchUtility
    # Set instance variables
    # return [AceIpProtoSpec] IP protocol object
    # raise [AclArgumentError]
    def define_protocol
      if @options.key?(:protocol)
        protocol = @options[:protocol]
        case protocol
        when AceIpProtoSpec
          protocol
        else
          AceIpProtoSpec.new(protocol)
        end
      else
        fail AclArgumentError, 'Not specified IP protocol'
      end
    end

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

    # Generate ACE search(contains?) conditions
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
  end # module ExtendedAceSearchUtility

  # ACE for extended access list
  class ExtendedAce < StandardAce
    include ExtendedAceSearchUtility

    # @param [AceIpProtoSpec] value L3/L4 protocol
    # @return [AceIpProtoSpec]
    attr_accessor :protocol

    # @param [AceSrcDstSpec] value Destination spec object
    # @return [AceSrcDstSpec]
    attr_accessor :dst_spec

    # @param [AceTcpFlagList] value
    #   TCP flags (used when '@protocol':tcp)
    # @return [AceTcpFlagList]
    attr_accessor :tcp_flags

    # @param [AceOtherQualifierList] value
    #   TCP other qualifier list object (used when '@protocol':tcp)
    # @return [AceOtherQualifierList]
    attr_accessor :tcp_other_qualifiers

    # Option,
    # :src and :dst can handle multiple types of object generation,
    # so that the argments can takes hash of AceSrcDstSpec.new or
    # AceSrcDstSpec instance.
    # :protocol and so on. (AceIpProtoSpec Object)
    #
    # about :protocol, it has specification of name and number
    # (specified in internal of parser).
    # basically, it is OK that specify only name.
    # (does it convert name <=> number each oether?)
    # (does it use number?
    #

    # Constructor
    # @param [Hash] opts Options
    # @option opts [String] :protocol L3/L4 protocol
    # @option opts [Integer] :number Protocol/Port number
    # @option opts [String] :action Action
    # @option opts [AceSrcDstSpec] :src Source spec object
    # @option opts [Hash] :src Source spec parmeters
    # @option opts [AceSrcDstSpec] :dst Destination spec object
    # @option opts [Hash] :dst Destination spec parmeters
    # @option opts [AceTcpFlagList] :tcp_port_qualifier
    #   TCP Flags object
    # @raise [AclArgumentError]
    # @return [ExtendACE]
    #
    # @example Construct ACE object
    #   ExtendACE.new(
    #     :protocol => 'tcp',
    #     :number => 10,
    #     :action => 'permit',
    #     :src => { :ipaddr => '192.168.3.0', :wildcard => '0.0.0.127' },
    #     :dst => { :ipaddr => '172.30.0.0', :wildcard => '0.0.7.127',
    #               :operator => 'eq', :begin_port => 80 })
    #
    def initialize(opts)
      super
      @options = opts
      @protocol = define_protocol
      @dst_spec = define_dst_spec
      @tcp_flags = define_tcp_flags
      @tcp_other_qualifiers = nil # not yet.
    end

    # @param [ExtendACE] other RHS object
    # @return [Boolean]
    def ==(other)
      @action == other.action &&
        @protocol == other.protocol &&
        @src_spec == other.src_spec &&
        @dst_spec == other.dst_spec &&
        @tcp_flags == other.tcp_flags
      ## does it need to compare? : tcp_other_qualifiers
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      format(
        '%s %s %s %s %s %s',
        tag_action(@action.to_s),
        tag_protocol(@protocol.to_s),
        @src_spec,
        @dst_spec,
        @tcp_flags,
        @tcp_other_qualifiers
     )
    end

    # Search matched ACE
    # @param [Hash] opts Options (target packet info)
    # @option opts [Integer,String] protocol L3 protocol No./Name
    # @option opts [String] src_ip Source IP Address
    # @option opts [String] src_operator Source port operator.
    # @option opts [Integer,String] src_begin_port Source Port No./Name
    # @option opts [Integer,String] src_end_port Source Port No./Name
    # @option opts [String] dst_ip Destination IP Address
    # @option opts [Integer,String] dst_begin_port Destination Port No./Name
    # @option opts [Integer,String] dst_end_port Destination Port No./Name
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError]
    # @see SingleAceBase#search_ace
    def contains?(opts)
      if opts.key?(:protocol)
        # generate proto/src/dst object by search conditions
        (proto_cond, src_cond, dst_cond) = search_conditions(opts)
        # check if search conditions are matches self.
        @protocol.contains?(proto_cond) &&
          @src_spec.contains?(src_cond) &&
          @dst_spec.contains?(dst_cond)
      else
        fail AclArgumentError, 'Invalid match target protocol'
      end
    end

    private

    # Set instance variables
    # @return [AceSrcDstSpec] Destination spec object
    # @raise [AclArgumentError]
    def define_dst_spec
      if @options.key?(:dst)
        dst = @options[:dst]
        case dst
        when Hash
          AceSrcDstSpec.new(dst)
        when AceSrcDstSpec
          dst
        else
          fail AclArgumentError, 'Dst spec: unknown class'
        end
      else
        fail AclArgumentError, 'Not specified dst spec'
      end
    end

    # Set instance variables
    # @return [AceOtherQualifierList]
    def define_tcp_flags
      if @protocol.name == 'tcp' && @options.key?(:tcp_flags_qualifier)
        @options[:tcp_flags_qualifier]
      else
        nil
      end
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
