# -*- coding: utf-8 -*-

require 'cisco_acl_intp/acl_base'

module CiscoAclIntp
  # IP/TCP/UDP port number and protocol name container base
  class AceProtoSpecBase < AclContainerBase
    # @param [String] value Protocol name,
    #   it is literal used in Cisco IOS access-list
    # @return [String]
    attr_accessor :name

    # @param [Integer] value Protocol/Port number
    # @return [Integer]
    attr_accessor :number

    # @return [String, Symbol] L3/L4 protocol type
    attr_reader :protocol

    # Constructor
    # @param [Hash] opts Options
    # @option opts [String] :name Protocol name
    # @option opts [Integer] :number Protocol/Port number
    # @raise [AclArgumentError]
    # @return [AceProtoSpecBase]
    # @abstract
    # @note Variable '@protocol'
    #   should be assigned in inherited class constructor,
    #   at first. (before call super class constructor)
    def initialize(opts)
      define_values(opts)

      # arguments     |
      # :name :number | @name         @number
      # --------------+----------------------------
      # set   set     | use arg       use arg (*1)
      #       none    | use arg       nil     (*2)
      # none  set     | nil           use arg (*3)
      #       none    | [    raise error    ] (*4)
      #
      # (*1) args are set in parser (assume correct args)
      #    check if :name and number_to_name(:number) are same.
      # (*2) args are set in parser (assume correct args)
      # (*3)

      validate_protocol_number
      validate_protocol_name_and_number
    end

    # Check the port number in valid range of port number
    # @abstract
    # @param [Integer] port IP/TCP/UDP port/protocol number
    # @return [Boolean]
    def valid_range?(port)
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      @name || number_to_name(@number)
    end

    # Convert protocol/port number to string (its name)
    # @abstract
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    #   If does not match the number in IOS proto/port literal,
    #   return number.to_s string
    def number_to_name(number)
      number.to_s
    end

    # @return [Integer] Protocol/Port number
    def to_i
      @number
    end

    # @return [Boolean] Compare with protocol/port number
    def <(other)
      @number < other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def >(other)
      @number > other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def <=(other)
      @number <= other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def >=(other)
      @number >= other.to_i
    end

    # @return [Fixnum] Compare with protocol/port number
    def <=>(other)
      @number <=> other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def ==(other)
      @protocol == other.protocol &&
        @name == other.name &&
        @number == other.number
    end

    private

    # Set instance variables with ip/default-netmask
    # @param [Hash] opts Options of constructor
    def define_values(opts)
      @protocol = nil unless @protocol
      @name = opts[:name] || nil
      @number = opts[:number] || nil
    end

    # Validate protocol number
    # @raise [AclArgumentError]
    def validate_protocol_number
      if @number && (!valid_range?(@number))
        # Pattern (*1)(*3)
        fail AclArgumentError, "Wrong protocol number: #{ @number }"
      end
    end

    # Validate protocol name and number (combination)
    # @raise [AclArgumentError]
    def validate_protocol_name_and_number
      if @name && @number
        # Case (*1): check parameter match
        # Do not overwrite name by number converted name,
        # because args are configured in parser,
        # that name mismatch looks like a bug.
        if @name != number_to_name(@number)
          fail AclArgumentError, 'Specified protocol name and number not match'
        end
      elsif (!@name) && (!@number)
        # Case (*4):
        fail AclArgumentError, 'Not specified protocol name and number'
      else
        ## condition: @name && (!@number)
        # Case (*2): no-op
        # Usually, args are configured in parser.
        # If not specified the number, it is empty explicitly
        ## condition: (!@name) && @number
        # Case (*3): no-op
        # @name is used to stringify, convert @number to name in to_s
      end
    end
  end

  # IP protocol number/name container
  class AceIpProtoSpec < AceProtoSpecBase
    # Minimum port/protocol number
    MIN_PORT = 0
    # Maximum port/protocol number
    MAX_PORT = 255

    # convert table of tcp port/name
    IP_PROTO_NAME_TABLE = {
      51 => 'ahp',
      88 => 'eigrp',
      50 => 'esp',
      47 => 'gre',
      2 => 'igmp',
      9 => 'igrp',
      94 => 'ipinip',
      4 => 'nos',
      89 => 'ospf',
      108 => 'pcp',
      103 => 'pim',
      1 => 'icmp',
      6 => 'tcp',
      17 => 'udp'
    }

    # Constructor
    # @param [Hash] opts Options of {AceProtoSpecBase}
    # @return [AceIpProtoSpec]
    def initialize(opts)
      @protocol = :ip
      super
    end

    # Check the port number in valid range of port number
    # @param [Integer] port IP/TCP/UDP port/protocol number
    # @return [Boolean]
    def valid_range?(port)
      (MIN_PORT .. MAX_PORT).include?(port.to_i)
    end

    # Convert protocol/port number to string (its name)
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    def number_to_name(number)
      IP_PROTO_NAME_TABLE[number] || number.to_s
    end
  end

  # TCP/UDP port range validation feature
  module AceTcpUdpPortValidation
    # Minimum port/protocol number
    MIN_PORT = 0
    # Maximum port/protocol number
    MAX_PORT = 65_535

    # Check the port number in valid range of port number
    # @param [Integer] port TCP/UDP port/protocol number
    # @return [Boolean]
    def valid_range?(port)
      (MIN_PORT .. MAX_PORT).include?(port.to_i)
    end
  end

  # TCP protocol number/name container
  class AceTcpProtoSpec < AceProtoSpecBase
    include AceTcpUdpPortValidation

    # convert table of tcp port/name
    TCP_PORT_NAME_TABLE = {
      179 => 'bgp',
      19 => 'chargen',
      514 => 'cmd',
      13 => 'daytime',
      9 => 'discard',
      53 => 'domain',
      3949 => 'drip',
      7 => 'echo',
      512 => 'exec',
      79 => 'finger',
      21 => 'ftp',
      20 => 'ftp-data',
      70 => 'gopher',
      101 => 'hostname',
      113 => 'ident',
      194 => 'irc',
      543 => 'klogin',
      544 => 'kshell',
      513 => 'login',
      515 => 'lpd',
      119 => 'nntp',
      496 => 'pim-auto-rp',
      109 => 'pop2',
      110 => 'pop3',
      25 => 'smtp',
      111 => 'sunrpc',
      49 => 'tacacs',
      517 => 'talk',
      23 => 'telnet',
      37 => 'time',
      540 => 'uucp',
      43 => 'whois',
      80 => 'www'
    }

    # Constructor
    # @param [Hash] opts Options of {AceProtoSpecBase}
    # @return [AceTcpProtoSpec]
    def initialize(opts)
      @protocol = :tcp
      super
    end

    # Convert protocol to port number by string (its name)
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    def number_to_name(number)
      TCP_PORT_NAME_TABLE[number] || number.to_s
    end
  end

  # UDP protocol number/name container
  class AceUdpProtoSpec < AceProtoSpecBase
    include AceTcpUdpPortValidation

    # convert table of UDP port/name
    UDP_PORT_NAME_TABLE = {
      512 => 'biff',
      68 => 'bootpc',
      67 => 'bootps',
      9 => 'discard',
      195 => 'dnsix',
      53 => 'domain',
      7 => 'echo',
      500 => 'isakmp',
      434 => 'mobile-ip',
      42 => 'nameserver',
      138 => 'netbios-dgm',
      137 => 'netbios-ns',
      139 => 'netbios-ss',
      4500 => 'non500-isakmp',
      123 => 'ntp',
      496 => 'pim-auto-rp',
      520 => 'rip',
      161 => 'snmp',
      162 => 'snmptrap',
      111 => 'sunrpc',
      514 => 'syslog',
      49 => 'tacacs',
      517 => 'talk',
      69 => 'tftp',
      37 => 'time',
      513 => 'who',
      177 => 'xdmcp'
    }

    # Constructor
    # @param [Hash] opts Options of {AceProtoSpecBase}
    # @return [AceUdpProtoSpec]
    def initialize(opts)
      @protocol = :udp
      super
    end

    # Convert protocol/port number to string (its name)
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    def number_to_name(number)
      UDP_PORT_NAME_TABLE[number] || number.to_s
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
