# -*- coding: utf-8 -*-

require 'cisco_acl_intp/acl-base'

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
    def initialize opts
      # set defaults
      @protocol = nil if not @protocol

      @name = opts[:name] or nil
      @number = opts[:number] or nil

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

      if @number and not valid_range?( @number )
        # (*1)(*3)
        raise AclArgumentError, "Wrong protocol number: #{ @number }"
      end

      if @name and @number
        # (*1) check parameter match
        # Do not overwrite name by number converted name,
        # because args are configured in parser,
        # that name mismatch looks like a bug.
        if @name != number_to_name( @number )
          raise AclArgumentError, "Specified protocol name and literal/number not match"
        end
      elsif @name and not @number
        # (*2) no-op
        # Usually, args are configured in parser.
        # If not specified the number, it is empty explicitly
      elsif not @name and @number
        # (*3) no-op
        # @name is used to stringify, convert @number to name in to_s
      else
        # (*4)
        raise AclArgumentError, "Not specified protocol name and number"
      end

    end

    # Check the port number in valid range of port number
    # @abstract
    # @param [Integer] port IP/TCP/UDP port/protocol number
    # @return [Boolean]
    def valid_range? port
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      @name or number_to_name( @number )
    end

    # Convert protocol/port number to string (its name)
    # @abstract
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    #   If does not match the number in IOS proto/port literal,
    #   return number.to_s string
    def number_to_name number
      number.to_s
    end

    # @return [Integer] Protocol/Port number
    def to_i
      @number
    end

    # @return [Boolean] Compare with protocol/port number
    def < other
      @number < other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def > other
      @number > other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def <= other
      @number <= other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def >= other
      @number >= other.to_i
    end

    # @return [Fixnum] Compare with protocol/port number
    def <=> other
      @number <=> other.to_i
    end

    # @return [Boolean] Compare with protocol/port number
    def == other
      @protocol == other.protocol and
        @name == other.name and
        @number == other.number
    end
  end

  # IP protocol number/name container
  class AceIpProtoSpec < AceProtoSpecBase

    # Minimum port/protocol number
    MIN_PORT = 0
    # Maximum port/protocol number
    MAX_PORT = 255

    # Constructor
    # @param [Hash] opts Options of {AceProtoSpecBase}
    # @return [AceIpProtoSpec]
    def initialize opts
      @protocol = :ip
      super
    end

    # Check the port number in valid range of port number
    # @param [Integer] port IP/TCP/UDP port/protocol number
    # @return [Boolean]
    def valid_range? port
      MIN_PORT <= port.to_i && port.to_i <= MAX_PORT
    end

    # Convert protocol/port number to string (its name)
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    def number_to_name number
      case number
      when  51 then 'ahp'
      when  88 then 'eigrp'
      when  50 then 'esp'
      when  47 then 'gre'
      when   2 then 'igmp'
      when   9 then 'igrp'
      when  94 then 'ipinip'
      when   4 then 'nos'
      when  89 then 'ospf'
      when 108 then 'pcp'
      when 103 then 'pim'
      when   1 then 'icmp'
      when   6 then 'tcp'
      when  17 then 'udp'
      else          number.to_s
      end
    end
  end

  # TCP/UDP port range validation feature
  module AceTcpUdpPortValidation
    # Minimum port/protocol number
    MIN_PORT = 0
    # Maximum port/protocol number
    MAX_PORT = 65535

    # Check the port number in valid range of port number
    # @param [Integer] port TCP/UDP port/protocol number
    # @return [Boolean]
    def valid_range? port
      MIN_PORT <= port.to_i && port.to_i <= MAX_PORT
    end
  end

  # TCP protocol number/name container
  class AceTcpProtoSpec < AceProtoSpecBase
    include AceTcpUdpPortValidation

    # Constructor
    # @param [Hash] opts Options of {AceProtoSpecBase}
    # @return [AceTcpProtoSpec]
    def initialize opts
      @protocol = :tcp
      super
    end

    # Convert protocol/port number to string (its name)
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    def number_to_name number
      case number
      when  179 then 'bgp'
      when   19 then 'chargen'
      when  514 then 'cmd'
      when   13 then 'daytime'
      when    9 then 'discard'
      when   53 then 'domain'
      when 3949 then 'drip'
      when    7 then 'echo'
      when  512 then 'exec'
      when   79 then 'finger'
      when   21 then 'ftp'
      when   20 then 'ftp-data'
      when   70 then 'gopher'
      when  101 then 'hostname'
      when  113 then 'ident'
      when  194 then 'irc'
      when  543 then 'klogin'
      when  544 then 'kshell'
      when  513 then 'login'
      when  515 then 'lpd'
      when  119 then 'nntp'
      when  496 then 'pim-auto-rp'
      when  109 then 'pop2'
      when  110 then 'pop3'
      when   25 then 'smtp'
      when  111 then 'sunrpc'
      when  514 then 'syslog'
      when   49 then 'tacacs'
      when  517 then 'talk'
      when   23 then 'telnet'
      when   37 then 'time'
      when  540 then 'uucp'
      when   43 then 'whois'
      when   80 then 'www'
      else           number.to_s
      end
    end

  end

  # UDP protocol number/name container
  class AceUdpProtoSpec < AceProtoSpecBase
    include AceTcpUdpPortValidation

    # Constructor
    # @param [Hash] opts Options of {AceProtoSpecBase}
    # @return [AceUdpProtoSpec]
    def initialize opts
      @protocol = :udp
      super
    end

    # Convert protocol/port number to string (its name)
    # @param [Integer] number Protocol/Port number
    # @return [String] Name of protocol/port number.
    def number_to_name number
      case number
      when  512 then 'biff'
      when   68 then 'bootpc'
      when   67 then 'bootps'
      when    9 then 'discard'
      when  195 then 'dnsix'
      when   53 then 'domain'
      when    7 then 'echo'
      when  500 then 'isakmp'
      when  434 then 'mobile-ip'
      when   42 then 'nameserver'
      when  138 then 'netbios-dgm'
      when  137 then 'netbios-ns'
      when  139 then 'netbios-ss'
      when 4500 then 'non500-isakmp'
      when  123 then 'ntp'
      when  496 then 'pim-auto-rp'
      when  520 then 'rip'
      when  161 then 'snmp'
      when  162 then 'snmptrap'
      when  111 then 'sunrpc'
      when  514 then 'syslog'
      when   49 then 'tacacs'
      when  517 then 'talk'
      when   69 then 'tftp'
      when   37 then 'time'
      when  513 then 'who'
      when  177 then 'xdmcp'
      else           number.to_s
      end
    end
  end

end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
