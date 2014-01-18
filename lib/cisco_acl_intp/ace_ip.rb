# -*- coding: utf-8 -*-

require 'forwardable'
require 'netaddr'
require 'cisco_acl_intp/acl_base'

module CiscoAclIntp
  # IP Address and Wildcard mask container
  class AceIpSpec < AclContainerBase
    extend Forwardable

    # @param [NetAddr::CIDR] value IP address
    #   (dotted decimal notation)
    # @return [NetAddr::CIDR]
    attr_accessor :ipaddr

    # @param [Integer] value Netmask length
    # @return [Integer]
    attr_accessor :netmask

    # @param [String] value Wildcard mask
    #   (dotted decimal and bit flapped notation)
    # @return [String]
    attr_accessor :wildcard

    def_delegator :@ipaddr, :ip, :ipaddr
    # `contained_ip?' method is cidr(ipaddr/nn) operation
    def_delegator :@ipaddr, :is_contained?, :contained_ip?
    # `matches?' method is wildcard mask operation
    def_delegators :@ipaddr, :matches?

    # Constructor
    # @param [Hash] opts Options
    # @option opts [String] :ipaddr IP address
    #   (dotted decimal notation)
    # @option opts [String] :wildcard Wildcard mask
    #   (dotted decimal and bit flipped notation)
    # @option opts [Integer] :netmask Network Mask Length
    # @raise [AclArgumentError]
    # @return [AceIpSpec]
    def initialize(opts)
      if opts.key?(:ipaddr)
        define_addrinfo(opts)
      else
        fail AclArgumentError, 'Not specified IP address'
      end
    end

    # @param [AceIpSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @ipaddr == other.ipaddr &&
        @netmask == other.netmask &&
        @wildcard == other.wildcard
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      if to_wmasked_ip_s == '0.0.0.0'
        # ip = '0.0.0.0' or wildcard = '255.255.255.255'
        c_ip('any')
      else
        if @wildcard == '0.0.0.0'
          # /32 mask
          sprintf('%s %s', c_mask('host'), c_ip(@ipaddr.ip))
        else
          sprintf('%s %s', c_ip(to_wmasked_ip_s), c_mask(@wildcard))
        end
      end
    end

    # Generate wildcard-masked ip address string
    # @return [String] wildcard-masked ip address string
    def to_wmasked_ip_s
      ai = NetAddr.ip_to_i(@ipaddr.ip)
      mi = NetAddr.ip_to_i(@ipaddr.wildcard_mask)
      ami = ai & mi
      NetAddr.i_to_ip(ami)
    end

    private

    # Set instance variables
    # @param [Hash] opts Options of constructor
    def define_addrinfo(opts)
      case
      when opts[:wildcard]
        define_addrinfo_with_wildcard(opts)
      when opts[:netmask]
        define_addrinfo_with_netmask(opts)
      else
        define_addrinfo_with_default_netmask(opts)
      end
    end

    # Set instance variables with ip/wildcard
    # @param [Hash] opts Options of constructor
    def define_addrinfo_with_wildcard(opts)
      @wildcard = opts[:wildcard]
      @ipaddr = NetAddr::CIDR.create(
        opts[:ipaddr],
        WildcardMask: [@wildcard, true]
      )
      ## TBD : is it OK? must convert if possible?
      @netmask = nil
    end

    # Set instance variables with ip/netmask
    # @param [Hash] opts Options of constructor
    def define_addrinfo_with_netmask(opts)
      @netmask = opts[:netmask]
      @ipaddr = NetAddr::CIDR.create(
        [opts[:ipaddr], @netmask].join('/')
      )
      @wildcard = @ipaddr.wildcard_mask(true)
    end

    # Set instance variables with ip/default-netmask
    # @param [Hash] opts Options of constructor
    def define_addrinfo_with_default_netmask(opts)
      # default mask
      @netmask = '255.255.255.255'
      @ipaddr = NetAddr::CIDR.create(
        [opts[:ipaddr], @netmask].join(' ')
      )
      @wildcard = @ipaddr.wildcard_mask(true)
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
