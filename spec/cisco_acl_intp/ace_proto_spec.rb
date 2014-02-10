# -*- coding: utf-8 -*-
require 'spec_helper'

def get_port_table(data)
  data.split(/\n/).reduce({}) do |tbl, line|
    md = line.match(/^\s*([\w\d\-]+)\s+.+[\s\(](\d+)\)$/)
    tbl[md[1]] = md[2] if md
    tbl
  end
end

def get_codes(port_table, classname)
  port_table.each_pair.reduce([]) do |list, (key, value)|
    list.push(<<"EOL")
      it 'should be [#{key}] when only number:#{value} specified' do
        aups = #{classname}.new(:number => #{value})
        aups.to_s.should be_aclstr('#{key}')
      end
EOL
  end
end

def number_data_to_codes(data, classname)
  port_table = get_port_table(data)
  codes = get_codes(port_table, classname)
  codes.join
end

describe AceUdpProtoSpec do
  describe '#name_to_numer' do
    it 'should be "111" by converting proto name "sunrpc"' do
      aups = AceUdpProtoSpec.new(name: 'sunrpc')
      aups.number.should eq 111
    end

    it 'should be raise error by converting unknown proto name "hoge"' do
      lambda do
        AceUdpProtoSpec.new(name: 'hoge')
      end.should raise_error(AclArgumentError)
    end
  end

  describe '#to_s' do
    udp_port_data = <<'EOL'
biff           Biff (mail notification, comsat, 512)
bootpc         Bootstrap Protocol (BOOTP) client (68)
bootps         Bootstrap Protocol (BOOTP) server (67)
discard        Discard (9)
dnsix          DNSIX security protocol auditing (195)
domain         Domain Name Service (DNS, 53)
echo           Echo (7)
isakmp         Internet Security Association and Key Management Protocol (500)
mobile-ip      Mobile IP registration (434)
nameserver     IEN116 name service (obsolete, 42)
netbios-dgm    NetBios datagram service (138)
netbios-ns     NetBios name service (137)
netbios-ss     NetBios session service (139)
non500-isakmp  Internet Security Association and Key Management Protocol (4500)
ntp            Network Time Protocol (123)
pim-auto-rp    PIM Auto-RP (496)
rip            Routing Information Protocol (router, in.routed, 520)
snmp           Simple Network Management Protocol (161)
snmptrap       SNMP Traps (162)
sunrpc         Sun Remote Procedure Call (111)
syslog         System Logger (514)
tacacs         TAC Access Control System (49)
talk           Talk (517)
tftp           Trivial File Transfer Protocol (69)
time           Time (37)
who            Who service (rwho, 513)
xdmcp          X Display Manager Control Protocol (177)
EOL
    codes = number_data_to_codes(udp_port_data, 'AceUdpProtoSpec')
    instance_eval(codes)

    it 'should be number string when it not match IOS acl literal' do
      aups = AceUdpProtoSpec.new(number: 3_333)
      aups.to_s.should be_aclstr('3333')
    end

    it 'raise error when out of range port number' do
      lambda do
        AceUdpProtoSpec.new(number: 65_536)
      end.should raise_error(AclArgumentError)

      lambda do
        AceUdpProtoSpec.new(number: -1)
      end.should raise_error(AclArgumentError)
    end

    it 'raise error when specified name and number literal are not match' do
      lambda do
        AceUdpProtoSpec.new(
          name: 'time',
          number: 49
        )
      end.should raise_error(AclArgumentError)
    end
  end
end

describe AceTcpProtoSpec do
  describe '#name_to_numer' do
    it 'should be "49" by converting proto name "tacacs"' do
      atps = AceTcpProtoSpec.new(name: 'tacacs')
      atps.number.should eq 49
    end

    it 'should be raise error by converting unknown proto name "fuga"' do
      lambda do
        AceTcpProtoSpec.new(name: 'fuga')
      end.should raise_error(AclArgumentError)
    end
  end

  describe '#to_s' do
    tcp_port_data = <<'EOL'
bgp          Border Gateway Protocol (179)
chargen      Character generator (19
cmd          Remote commands (rcmd, 514)
daytime      Daytime (13)
discard      Discard (9)
domain       Domain Name Service (53)
drip         Dynamic Routing Information Protocol (3949)
echo         Echo (7)
exec         Exec (rsh, 512)
finger       Finger (79)
ftp          File Transfer Protocol (21)
ftp-data     FTP data connections (20)
gopher       Gopher (70)
hostname     NIC hostname server (101)
ident        Ident Protocol (113)
irc          Internet Relay Chat (194)
klogin       Kerberos login (543)
kshell       Kerberos shell (544)
login        Login (rlogin, 513)
lpd          Printer service (515)
nntp         Network News Transport Protocol (119)
pim-auto-rp  PIM Auto-RP (496)
pop2         Post Office Protocol v2 (109)
pop3         Post Office Protocol v3 (110)
smtp         Simple Mail Transport Protocol (25)
sunrpc       Sun Remote Procedure Call (111)
tacacs       TAC Access Control System (49)
talk         Talk (517)
telnet       Telnet (23)
time         Time (37)
uucp         Unix-to-Unix Copy Program (540)
whois        Nicname (43)
www          World Wide Web (HTTP, 80)
EOL
    codes = number_data_to_codes(tcp_port_data, 'AceTcpProtoSpec')
    instance_eval(codes)

    it 'should be number string when it not match IOS acl literal' do
      aups = AceTcpProtoSpec.new(number: 6_633)
      aups.to_s.should be_aclstr('6633')
    end

    it 'raise error when out of range port number' do
      lambda do
        AceTcpProtoSpec.new(number: 65_536)
      end.should raise_error(AclArgumentError)

      lambda do
        AceTcpProtoSpec.new(number: -1)
      end.should raise_error(AclArgumentError)
    end

    it 'raise error when specified name and number literal are not match' do
      lambda do
        AceUdpProtoSpec.new(
          name: 'bgp',
          number: 517
        )
      end.should raise_error(AclArgumentError)
    end
  end
end

describe AceIpProtoSpec do
  describe '#name_to_numer' do
    it 'should be "88" by converting proto name "eigrp"' do
      aips = AceIpProtoSpec.new(name: 'eigrp')
      aips.number.should eq 88
    end

    it 'should be raise error by converting unknown proto name "foo"' do
      lambda do
        AceIpProtoSpec.new(name: 'foo')
      end.should raise_error(AclArgumentError)
    end
  end

  describe '#to_s' do
    ip_port_data = <<'EOL'
ahp           Authentication Header Protocol (51)
eigrp         Cisco's EIGRP routing protocol (88)
esp           Encapsulation Security Payload (50)
gre           Cisco's GRE tunneling (47)
icmp          Internet Control Message Protocol (1)
igmp          Internet Gateway Message Protocol (2)
ipinip        IP in IP tunneling (94)
nos           KA9Q NOS compatible IP over IP tunneling (4)
ospf          OSPF routing protocol (89)
pcp           Payload Compression Protocol (108)
pim           Protocol Independent Multicast (103)
tcp           Transmission Control Protocol (6)
udp           User Datagram Protocol (17)
EOL
    codes = number_data_to_codes(ip_port_data, 'AceIpProtoSpec')
    instance_eval(codes)

    it 'should be number string when it not match IOS acl literal' do
      aups = AceIpProtoSpec.new(number: 255)
      aups.to_s.should be_aclstr('255')
    end

    it 'raise error when out of range port number' do
      lambda do
        AceIpProtoSpec.new(number: 256)
      end.should raise_error(AclArgumentError)

      lambda do
        AceIpProtoSpec.new(number: -1)
      end.should raise_error(AclArgumentError)
    end

    it 'raise error when specified name and number literal are not match' do
      lambda do
        AceTcpProtoSpec.new(
          name: 'ospf',
          number: 17
        )
      end.should raise_error(AclArgumentError)
    end

  end
end
