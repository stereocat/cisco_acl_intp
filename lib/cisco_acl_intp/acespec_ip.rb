# frozen_string_literal: true

require 'forwardable'
require 'netaddr'
require 'cisco_acl_intp/acespec_base'

module CiscoAclIntp
  # IP Address and Wildcard mask container
  class AceIpSpec < AceSpecBase
    extend Forwardable

    # @param [NetAddr::CIDR] value IP address
    #   (dotted decimal notation)
    # @return [NetAddr::CIDR]
    attr_reader :ipaddr

    # @param [Integer] value Netmask *length*
    # @return [Integer]
    attr_reader :netmask

    # @param [String] value Wildcard mask
    #   (dotted decimal and bit flapped notation)
    # @return [String]
    attr_reader :wildcard

    # `matches?' method is wildcard mask operation
    def_delegators :@ipaddr, :matches?, :contains?
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
      super()
      raise AclArgumentError, 'Not specified IP address' unless opts.key?(:ipaddr)

      @options = opts
      define_addrinfo
    end

    # @param [AceIpSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @ipaddr == other.ipaddr && ip == other.ip &&
        @netmask == other.netmask && @wildcard == other.wildcard
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      if to_wmasked_ip_s == '0.0.0.0'
        # ip = '0.0.0.0' or wildcard = '255.255.255.255'
        tag_ip('any')
      elsif @wildcard == '0.0.0.0'
        # /32 mask
        format '%<host>s %<ip>s', host: tag_mask('host'), ip: tag_ip(@ipaddr.ip)
      else
        format '%<ip>s %<mask>s', ip: tag_ip(to_wmasked_ip_s), mask: tag_mask(@wildcard)
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
    }.freeze

    # Covnet IPv4 bit-flapped wildcard to netmask length
    # @return [Fixnum] netmask length
    #   or `nil` when discontinuous-bits-wildcard-mask
    # @todo Known bug: it cannot handle wrong wildcard,
    #   e.g. '0.0.0.1.255' #=> 31
    def wildcard_bitlength
      @wildcard.split(/\./).reduce(0) do |len, octet|
        break unless len && OCTET_BIT_LENGTH.key?(octet)

        len + OCTET_BIT_LENGTH[octet]
      end
    end

    # Check ip addr string: alias 'any' ipaddr
    # @return [AceIpSpec] IP spec object.
    def check_ip_any_alias
      case @options[:ipaddr]
      when nil, '', 'any', /^\s*$/
        @options[:ipaddr] = '0.0.0.0'
        @options[:netmask] = 0
      end
    end

    # Set instance variables
    def define_addrinfo
      check_ip_any_alias
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
      # default ('host' mask)
      @options[:netmask] = 32 unless @options.key?(:netmask)
      define_addrinfo_with_netmask
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
        format('%<ip>s/%<mask>s', ip: @options[:ipaddr], mask: @netmask)
      )
      @wildcard = @ipaddr.wildcard_mask(true)
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
