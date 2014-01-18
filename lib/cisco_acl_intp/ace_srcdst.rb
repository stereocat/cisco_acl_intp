# -*- coding: utf-8 -*-

require 'netaddr'
require 'cisco_acl_intp/ace_ip'
require 'cisco_acl_intp/ace_port'
require 'cisco_acl_intp/ace_other_qualifiers'
require 'cisco_acl_intp/ace_tcp_flags'

module CiscoAclIntp
  # IP Address and TCP/UDP Port Info
  class AceSrcDstSpec < AclContainerBase
    ## TBD
    ## Src/Dst takes Network Object Group or IP/wildcard.
    ## object group is not implemented yet.

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
    # @option opts [AcePortSpec] :port_spec Port/Operator object
    # @option opts [String] :operator Port operator
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
      @ip_spec = define_ipspec(opts)
      @port_spec = define_portspec(opts)
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
      sprintf('%s %s', @ip_spec, @port_spec)
    end

    # Check address and port number matche this object.
    # @param [String] address IP address (dotted notation)
    # @param [Integer] port Port No.
    # @return [Boolean]
    def matches?(address, port = nil)
      ip_spec_match = @ip_spec.matches?(address)
      ip_spec_match && @port_spec.matches?(port) if port
    end

    private

    # Set instance variables
    # @param [Hash] opts Options of constructor
    # @raise [AclArgumentError]
    # @return [AceIpSpec] IP address/Mask object
    # @see #initialize
    def define_ipspec(opts)
      if opts.key?(:ip_spec)
        opts[:ip_spec]
      elsif opts.key?(:ipaddr)
        AceIpSpec.new(
          ipaddr: opts[:ipaddr],
          wildcard: opts[:wildcard]
        )
      else
        fail AclArgumentError, 'Not specified: ip spec'
      end
    end

    # Set instance variables
    # @param [Hash] opts Options of constructor
    # @return [AcePortSpec] Port/Operator object
    # @see #initialize
    def define_portspec(opts)
      if opts.key?(:port_spec)
        opts[:port_spec]
      elsif opts.key?(:operator)
        AcePortSpec.new(
          operator: opts[:operator],
          begin_port: opts[:port] || opts[:begin_port],
          end_port: opts[:end_port]
        )
      else
        # in standard acl, not used port_spec
        # if not specified port spec: default: any port
        AcePortSpec.new(operator: 'any')
      end
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
