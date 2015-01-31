# -*- coding: utf-8 -*-
require 'cisco_acl_intp/standard_ace'

module CiscoAclIntp
  # ACE for extended access list
  class ExtendedAce < StandardAce
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
    # @param [ExtendedAce] other Target ACE
    # @return [Boolean] Matched or not
    # @see SingleAceBase#search_ace
    def contains?(other)
      super(other) &&
        @protocol.contains?(other.protocol) &&
        @dst_spec.contains?(other.dst_spec)
    end

    private

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
      return unless @protocol.name == 'tcp' &&
                    @options.key?(:tcp_flags_qualifier)
      @options[:tcp_flags_qualifier]
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
