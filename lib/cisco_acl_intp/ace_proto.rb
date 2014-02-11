# -*- coding: utf-8 -*-

require 'cisco_acl_intp/acl_base'

module CiscoAclIntp
  # IP/TCP/UDP port number and protocol name container base
  class AceProtoSpecBase < AclContainerBase
    include Comparable

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
      @options = opts
      define_values
      # (*1),(*3): check when @number exists
      validate_protocol_number
      # (*1)-(*4)
      validate_protocol_name_and_number
    end

    # Check the port number in valid range of port number
    # @abstract
    # @return [Boolean]
    def valid_range?
      @number.integer?
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      @name || number_to_name
    end

    # Return protocol/port number
    # @return [Integer] Protocol/Port number
    def to_i
      @number.to_i
    end

    # Convert protocol/port number to string (its name)
    # @abstract
    # @return [String] Name of protocol/port number.
    #   If does not match the number in IOS proto/port literal,
    #   return number.to_s string
    def number_to_name
      @number.to_s
    end

    # Convert protocol/port name to number
    # @abstract
    # @raise [AclArgumentError]
    def name_to_number
      fail AclArgumentError, 'abstract method: name_to_number called'
    end

    # Compare by port number
    # @note Using "Comparable" module, '==' operator is defined by
    #   '<=>' operator. But '==' is overriden to compare instance
    #   equivalence instead of port number comparison.
    # @param [AceProtoSpecBase] other Compared instance
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

    # arguments     |
    # :name :number | @name         @number
    # --------------+----------------------------
    # set   set     | use arg       use arg (*1)
    #       none    | use arg       nil     (*2)
    # none  set     | nil           use arg (*3)
    #       none    | [    raise error    ] (*4)
    #
    # (*1) args are set in parser (assume correct args)
    #    check if :name and number_to_name are same.
    # (*2) args are set in parser (assume correct args)
    # (*3)

    # argment check: case (*1)
    # @return [Boolean]
    def arg_name_and_number_exists
      @name && @number
    end

    # argment check: case (*2)
    # @return [Boolean]
    def arg_name_exists
      @name && (!@number)
    end

    # argment check: case (*3)
    # @return [Boolean]
    def arg_number_exists
      (!@name) && @number
    end

    # argment check: case (*4)
    # @return [Boolean]
    def arg_name_and_number_lost
      (!@name) && (!@number)
    end

    # Set instance variables with ip/default-netmask
    def define_values
      @protocol = nil unless @protocol
      @name = @options[:name] || nil
      @number = @options[:number] || nil
    end

    # Validate protocol number
    # @raise [AclArgumentError]
    def validate_protocol_number
      if @number
        @number = (@number.instance_of?(String) ? @number.to_i : @number)
        unless valid_range?
          # Pattern (*1)(*3)
          fail AclArgumentError, "Wrong protocol number: #{@number}"
        end
      end
    end

    # Validate protocol name and number (combination)
    # @raise [AclArgumentError]
    def validate_protocol_name_and_number
      case
      when arg_name_and_number_exists
        # Case (*1): check parameter match
        if @name != number_to_name
          fail AclArgumentError, 'Specified protocol name and number not match'
        end
      when arg_name_exists
        # Case (*2): try to convert from name to number
        @number = name_to_number
      when arg_number_exists
        # Case (*3): try to convert from number to name
        @name = number_to_name
      when arg_name_and_number_lost
        # Case (*4): raise error
        fail AclArgumentError, 'Not specified protocol name and number'
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
    # @note protol='ip' means ANY ip protocol in Cisco IOS ACL.
    #  not defined 'ip' in IANA,
    #  http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
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
      17 => 'udp',
      -1 => 'ip' # dummy number
    }

    # Constructor
    # @param [Hash] opts Options of <AceProtoSpecBase>
    # @return [AceIpProtoSpec]
    def initialize(opts)
      @protocol = :ip
      super
    end

    # Check the port number in valid range of port number
    # @return [Boolean]
    def valid_range?
      (MIN_PORT .. MAX_PORT).include?(@number)
    end

    # Check the port name is known or not.
    # @param [String] name IP/TCP/UDP port/protocol name
    # @return [Boolean]
    def self.valid_name?(name)
      IP_PROTO_NAME_TABLE.value?(name)
    end

    # Convert protocol/port number to string (its name)
    # @return [String] Name of protocol/port number.
    def number_to_name
      IP_PROTO_NAME_TABLE[@number] || @number.to_s
    end

    # Convert protocol/port name to number
    # @return [String] Number of protocol/port name
    # @raise [AclArgumentError]
    def name_to_number
      if IP_PROTO_NAME_TABLE.value?(@name)
        IP_PROTO_NAME_TABLE.invert[@name]
      else
        fail AclArgumentError, "Unknown ip protocol name: #{@name}"
      end
    end
  end

  # TCP/UDP port range validation feature
  class AceTcpUdpProtoSpec < AceProtoSpecBase
    # Minimum port/protocol number
    MIN_PORT = 0
    # Maximum port/protocol number
    MAX_PORT = 65_535

    # Constructor
    # @param [Hash] opts Options of <AceProtoSpecBase>
    # @return [AceTcpProtoSpec]
    def initialize(opts)
      @protocol = :tcp_udp
      super
    end

    # Check the port number in valid range of port number
    # @return [Boolean]
    def valid_range?
      (MIN_PORT .. MAX_PORT).include?(@number)
    end
  end

  # TCP protocol number/name container
  class AceTcpProtoSpec < AceTcpUdpProtoSpec
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
    # @param [Hash] opts Options of <AceProtoSpecBase>
    # @return [AceTcpProtoSpec]
    def initialize(opts)
      @protocol = :tcp
      super
    end

    # Check the port name is known or not.
    # @param [String] name IP/TCP/UDP port/protocol name
    # @return [Boolean]
    def self.valid_name?(name)
      TCP_PORT_NAME_TABLE.value?(name)
    end

    # Convert protocol to port number by string (its name)
    # @return [String] Name of protocol/port number.
    def number_to_name
      TCP_PORT_NAME_TABLE[@number] || @number.to_s
    end

    # Convert protocol/port name to number
    # @return [String] Number of protocol/port name
    # @raise [AclArgumentError]
    def name_to_number
      if TCP_PORT_NAME_TABLE.value?(@name)
        TCP_PORT_NAME_TABLE.invert[@name]
      else
        fail AclArgumentError, "Unknown tcp port name: #{@name}"
      end
    end
  end

  # UDP protocol number/name container
  class AceUdpProtoSpec < AceTcpUdpProtoSpec
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
    # @param [Hash] opts Options of <AceProtoSpecBase>
    # @return [AceUdpProtoSpec]
    def initialize(opts)
      @protocol = :udp
      super
    end

    # Check the port name is known or not.
    # @param [String] name IP/TCP/UDP port/protocol name
    # @return [Boolean]
    def self.valid_name?(name)
      UDP_PORT_NAME_TABLE.value?(name)
    end

    # Convert protocol/port number to string (its name)
    # @return [String] Name of protocol/port number.
    def number_to_name
      UDP_PORT_NAME_TABLE[@number] || @number.to_s
    end

    # Convert protocol/port name to number
    # @return [String] Number of protocol/port name
    # @raise [AclArgumentError]
    def name_to_number
      if UDP_PORT_NAME_TABLE.value?(@name)
        UDP_PORT_NAME_TABLE.invert[@name]
      else
        fail AclArgumentError, "Unknown udp port name: #{@name}"
      end
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
