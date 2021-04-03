# frozen_string_literal: true

require 'netaddr'
require 'cisco_acl_intp/acespec_ip'
require 'cisco_acl_intp/acespec_port'
require 'cisco_acl_intp/acespec_other_qualifiers'
require 'cisco_acl_intp/acespec_tcp_flags'

module CiscoAclIntp
  # IP Address and TCP/UDP Port Info
  # @todo Src/Dst takes Network Object Group or IP/wildcard.
  #    "object-group" is not implemented yet.
  class AceSrcDstSpec < AceSpecBase
    # @param [AceIpSpec] value IP address and Wildcard-mask
    # @return [AceIpSpec]
    attr_accessor :ip_spec

    # @param [AcePortSpec] value Port number(s) and Operator
    # @return [AcePortSpec]
    attr_accessor :port_spec

    # Constructor
    # @param [Hash] opts Options
    # @option opts [AceIpSpec] :ip_spec IP address/Mask object
    # @option opts [String] :ipaddr IP Address (dotted notation)
    # @option opts [String] :wildcard Wildcard mask
    #   (dotted/bit-flipped notation)
    # @option opts [Integer] :netmask Subnet mask length (e.g. 24)
    # @option opts [AcePortSpec] :port_spec Port/Operator object
    # @option opts [String, Symbol] :operator Port operator
    # @option opts [AceProtoSpecBase] :port port number (single/lower)
    #   (same as :begin_port, alias for unary operator)
    # @option opts [AceProtoSpecBase] :begin_port port number (single/lower)
    # @option opts [AceProtoSpecBase] :end_port port number (higher)
    # @raise [AclArgumentError]
    # @return [AceSrcDstSpec]
    # @note When it does not specified port in opts,
    #   (:port_spec or :operator, :begin_port, :end_port)
    #   it assumed with ANY port.
    def initialize(opts)
      super()
      @options = opts
      @ip_spec = define_ipspec
      @port_spec = define_portspec
    end

    # @param [AceSrcDstSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @port_spec == other.port_spec &&
        @ip_spec == other.ip_spec
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      format '%<ip>s %<port>s', ip: @ip_spec, port: @port_spec
    end

    # Check address and port number contains this object or not.
    # @param [AceSrcDstSpec] other Conditions to compare
    # @return [Boolean]
    # @raise [AclArgumentError]
    def contains?(other)
      contains_address?(other.ip_spec) &&
        contains_port?(other.port_spec)
    end

    private

    # Check port match
    # @param [AcePortSpec] port_spec TCP/UDP Port spec
    # @return [Boolean]
    def contains_port?(port_spec = nil)
      port_spec = AcePortSpec.new(operator: :any) if port_spec.nil?
      @port_spec.contains?(port_spec)
    end

    # Check address match (by NetAddr)
    # @param [AceIpSpec] ip_spec IP address spec.
    # @return [Boolean]
    def contains_address?(ip_spec = nil)
      case ip_spec
      when nil # 'any', '0.0.0.0/0'
        true
      else
        # IP match/contain checks are delegated to NetAddr
        if @ip_spec.netmask.nil?
          # check by wildcard
          @ip_spec.matches?(ip_spec.ipaddr)
        else
          # check by CIDR(netmask)
          @ip_spec.contains?(ip_spec.ipaddr)
        end
      end
    end

    # Set instance variables
    # @raise [AclArgumentError]
    # @return [AceIpSpec] IP address/Mask object
    # @see #initialize
    def define_ipspec
      if @options.key?(:ip_spec) # AceIpSpec Obj
        @options[:ip_spec]
      elsif @options.key?(:ipaddr)
        AceIpSpec.new(@options)
      else
        raise AclArgumentError, 'Not specified: ip spec'
      end
    end

    # Set instance variables
    # @return [AcePortSpec] Port/Operator object
    # @see #initialize
    def define_portspec
      if @options.key?(:port_spec) &&
         @options[:port_spec].is_a?(AcePortSpec)
        @options[:port_spec]
      elsif @options.key?(:operator)
        AcePortSpec.new(
          operator: @options[:operator],
          begin_port: @options[:port] || @options[:begin_port],
          end_port: @options[:end_port]
        )
      else
        # in standard acl, not used port_spec
        # if not specified port spec: default: any port.
        # port spec should be ignored except tcp/udp protocol.
        AcePortSpec.new(operator: 'any')
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
