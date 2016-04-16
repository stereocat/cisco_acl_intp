# -*- coding: utf-8 -*-
require 'cisco_acl_intp/acespec_proto_base'

module CiscoAclIntp
  # IP protocol number/name container
  class AceIpProtoSpec < AceProtoSpecBase
    # Convert table of tcp port/name
    # @note protol='ip' means ANY ip protocol in Cisco IOS ACL.
    #  not defined 'ip' in IANA,
    #  http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    IP_PROTO_TABLE = {
      'ahp' => 51,
      'eigrp' => 88,
      'esp' => 50,
      'gre' => 47,
      'igmp' => 2,
      'igrp' => 9,
      'ipinip' => 94,
      'nos' => 4,
      'ospf' => 89,
      'pcp' => 108,
      'pim' => 103,
      'icmp' => 1,
      'tcp' => 6,
      'udp' => 17,
      'ip' => -1 # dummy
    }.freeze

    # Constructor
    # @param [String, Integer] proto_id L3 Protocol ID (No. or Name)
    # @return [AceIpProtoSpec]
    def initialize(proto_id = nil)
      super(proto_id, 255)
      @protocol = :ip
    end

    # Protocol Table
    # @return [Hash] Protocol table
    def proto_table
      IP_PROTO_TABLE
    end

    # Check the port name is known or not.
    # @param [String] name IP/TCP/UDP port/protocol name
    # @return [Boolean]
    def self.valid_name?(name)
      IP_PROTO_TABLE.key?(name)
    end

    # check protocol is 'ip'?
    # @return [Boolean]
    def ip?
      @name == 'ip'
    end

    # check protocol is 'tcp'?
    # @return [Boolean]
    def tcp?
      @name == 'tcp'
    end

    # check protocol is 'udp'?
    # @return [Boolean]
    def udp?
      @name == 'udp'
    end

    # Protocol inclusion relation
    # @param [AceIpProtoSpec] other Other protocol spec
    def contains?(other)
      if ip?
        other.ip? || other.tcp? || other.udp?
      else
        self == other
      end
    end
  end

  # TCP/UDP port range validation feature
  class AceTcpUdpProtoSpec < AceProtoSpecBase
    # Constructor
    # @param [String, Integer] proto_id Protocol ID (No. or Name)
    # @return [AceTcpProtoSpec]
    def initialize(proto_id = nil)
      super(proto_id, 65_535)
      @protocol = :tcp_udp
    end
  end

  # TCP protocol number/name container
  class AceTcpProtoSpec < AceTcpUdpProtoSpec
    # convert table of tcp port/name
    TCP_PROTO_TABLE = {
      'bgp' => 179,
      'chargen' => 19,
      'cmd' => 514,
      'daytime' => 13,
      'discard' => 9,
      'domain' => 53,
      'drip' => 3949,
      'echo' => 7,
      'exec' => 512,
      'finger' => 79,
      'ftp' => 21,
      'ftp-data' => 20,
      'gopher' => 70,
      'hostname' => 101,
      'ident' => 113,
      'irc' => 194,
      'klogin' => 543,
      'kshell' => 544,
      'login' => 513,
      'lpd' => 515,
      'nntp' => 119,
      'pim-auto-rp' => 496,
      'pop2' => 109,
      'pop3' => 110,
      'smtp' => 25,
      'sunrpc' => 111,
      'tacacs' => 49,
      'talk' => 517,
      'telnet' => 23,
      'time' => 37,
      'uucp' => 540,
      'whois' => 43,
      'www' => 80
    }.freeze

    # Constructor
    # @param [String, Integer] proto_id Protocol ID (No. or Name)
    # @return [AceTcpProtoSpec]
    def initialize(proto_id = nil)
      super
      @protocol = :tcp
    end

    # Protocol Table
    # @return [Hash] Protocol table
    def proto_table
      TCP_PROTO_TABLE
    end

    # Check the port name is known or not.
    # @param [String] name IP/TCP/UDP port/protocol name
    # @return [Boolean]
    def self.valid_name?(name)
      TCP_PROTO_TABLE.key?(name)
    end
  end

  # UDP protocol number/name container
  class AceUdpProtoSpec < AceTcpUdpProtoSpec
    # convert table of UDP port/name
    UDP_PROTO_TABLE = {
      'biff' => 512,
      'bootpc' => 68,
      'bootps' => 67,
      'discard' => 9,
      'dnsix' => 195,
      'domain' => 53,
      'echo' => 7,
      'isakmp' => 500,
      'mobile-ip' => 434,
      'nameserver' => 42,
      'netbios-dgm' => 138,
      'netbios-ns' => 137,
      'netbios-ss' => 139,
      'non500-isakmp' => 4500,
      'ntp' => 123,
      'pim-auto-rp' => 496,
      'rip' => 520,
      'snmp' => 161,
      'snmptrap' => 162,
      'sunrpc' => 111,
      'syslog' => 514,
      'tacacs' => 49,
      'talk' => 517,
      'tftp' => 69,
      'time' => 37,
      'who' => 513,
      'xdmcp' => 177
    }.freeze

    # Constructor
    # @param [String, Integer] proto_id Protocol ID (No. or Name)
    # @return [AceUdpProtoSpec]
    def initialize(proto_id = nil)
      super
      @protocol = :udp
    end

    # Protocol Table
    # @return [Hash] Protocol table
    def proto_table
      UDP_PROTO_TABLE
    end

    # Check the port name is known or not.
    # @param [String] name IP/TCP/UDP port/protocol name
    # @return [Boolean]
    def self.valid_name?(name)
      UDP_PROTO_TABLE.key?(name)
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
