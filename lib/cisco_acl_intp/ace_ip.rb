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
    attr_reader :ipaddr

    # @param [Integer] value Netmask length
    # @return [Integer]
    attr_reader :netmask

    # @param [String] value Wildcard mask
    #   (dotted decimal and bit flapped notation)
    # @return [String]
    attr_reader :wildcard

    # `matches?' method is wildcard mask operation
    def_delegators :@ipaddr, :matches?
    # ip returns non-masked address
    def_delegators :@ipaddr, :ip

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
        @options = opts
        define_addrinfo
      else
        fail AclArgumentError, 'Not specified IP address'
      end
    end

    # @param [AceIpSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @ipaddr == other.ipaddr &&
        ip == other.ip &&
        @netmask == other.netmask &&
        @wildcard == other.wildcard
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      if to_wmasked_ip_s == '0.0.0.0'
        # ip = '0.0.0.0' or wildcard = '255.255.255.255'
        tag_ip('any')
      else
        if @wildcard == '0.0.0.0'
          # /32 mask
          sprintf('%s %s', tag_mask('host'), tag_ip(@ipaddr.ip))
        else
          sprintf('%s %s', tag_ip(to_wmasked_ip_s), tag_mask(@wildcard))
        end
      end
    end

    # Generate wildcard-masked ip address string
    # @return [String] wildcard-masked ip address string
    def to_wmasked_ip_s
      ai = NetAddr.ip_to_i(@ipaddr.ip)
      mi = NetAddr.ip_to_i(@ipaddr.wildcard_mask)
      NetAddr.i_to_ip(ai & mi)
    end

    # Check subnet contained this object or not.
    # @param [String] address Subnet address string
    #   e.g. 192.168.0.0/24, 192.168.0.0/255.255.255.0
    # @return [Boolean]
    # @raise [NetAddr::ValidationError]
    def contains?(address)
      # `@ipaddr` contains(1), is same block(0),
      # is `contained(-1), is not related(nil)
      [0, 1].include?(@ipaddr.cmp(address))
    end

    private

    # Convert table of IPv4 bit-flapped wildcard octet to bit length
    OCTET_BIT_LENGTH = {
      '255' => 0, '127' => 1, '63' => 2, '31' => 3,
      '15' => 4, '7' => 5, '3' => 6, '1' => 7, '0' => 8
    }

    # Covnet IPv4 bit-flapped wildcard to netmask length
    # @return [Fixnum] netmask length
    #   or `nil` when discontinuous-bits-wildcard-mask
    # @todo Known bug: it cannot handle wrong wildcard,
    #   e.g. '0.0.0.1.255' #=> 31
    def wildcard_bitlength
      @wildcard.split(/\./).reduce(0) do |len, octet|
        if len && OCTET_BIT_LENGTH.key?(octet)
          len + OCTET_BIT_LENGTH[octet]
        else
          nil
        end
      end
    end

    # Set instance variables
    def define_addrinfo
      if @options.key?(:wildcard)
        define_addrinfo_prefer_wildcard
      else
        define_addrinfo_by_netmask_or_default
      end
    end

    # Set instance variables. assume that wildcard is primary option.
    def define_addrinfo_prefer_wildcard
      @wildcard = @options[:wildcard]
      @netmask = wildcard_bitlength
      if @netmask
        @options[:netmask] = @netmask
        define_addrinfo_with_netmask
      else
        define_addrinfo_with_wildcard
      end
    end

    # Set instance variables. Secondary prioritize option is netmask,
    #   and third(last) one is default-mask
    def define_addrinfo_by_netmask_or_default
      if @options.key?(:netmask)
        define_addrinfo_with_netmask
      else
        define_addrinfo_with_default_netmask
      end
    end

    # Set instance variables with ip/wildcard
    def define_addrinfo_with_wildcard
      @ipaddr = NetAddr::CIDR.create(
        @options[:ipaddr],
        WildcardMask: [@wildcard, true]
      )
      @netmask = nil
    end

    # Set instance variables with ip/netmask
    def define_addrinfo_with_netmask
      @netmask = @options[:netmask]
      @ipaddr = NetAddr::CIDR.create(
        sprintf('%s/%s', @options[:ipaddr], @netmask)
      )
      @wildcard = @ipaddr.wildcard_mask(true)
    end

    # Set instance variables with ip/default-netmask
    def define_addrinfo_with_default_netmask
      # default mask
      @netmask = '255.255.255.255'
      @ipaddr = NetAddr::CIDR.create(
        [@options[:ipaddr], @netmask].join(' ')
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
