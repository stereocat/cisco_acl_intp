# frozen_string_literal: true

require 'spec_helper'

def get_port_table(data)
  data.split(/\n/).each_with_object({}) do |line, tbl|
    md = line.match(/^\s*([\w\d\-]+)\s+.+[\s(](\d+)\)$/)
    tbl[md[1]] = md[2] if md
    tbl
  end
end

def get_codes(port_table, classname)
  port_table.each_pair.reduce([]) do |list, (key, value)|
    list.push(<<"EOL")
      it 'should be [#{key}] when only number:#{value} specified' do
        aups = #{classname}.new(#{value})
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
  describe '#name_to_numer, #to_i' do
    it 'should be "111" by converting proto name "sunrpc"' do
      aups = AceUdpProtoSpec.new('sunrpc')
      expect(aups.number).to eq 111
      expect(aups.to_i).to eq 111
    end

    it 'should be error by converting unknown proto name "hoge"' do
      expect do
        AceUdpProtoSpec.new('hoge')
      end.to raise_error(AclArgumentError)
    end
  end

  describe 'class#valid_name?' do
    it 'should be true when valid udp port name' do
      expect(AceUdpProtoSpec.valid_name?('snmp')).to be_truthy
    end

    it 'should be false when invalid udp port name' do
      expect(AceUdpProtoSpec.valid_name?('daytime')).to be_falsey
    end
  end

  describe '#to_s' do
    udp_port_data = <<~'EOL'
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
      aups = AceUdpProtoSpec.new(3_333)
      expect(aups.to_s).to be_aclstr('3333')
    end

    it 'should be error when out of range port number' do
      expect do
        AceUdpProtoSpec.new(65_536)
      end.to raise_error(AclArgumentError)

      expect do
        AceUdpProtoSpec.new(-1)
      end.to raise_error(AclArgumentError)
    end

    it 'should be error when not specified name/number' do
      expect do
        AceUdpProtoSpec.new
      end.to raise_error(AclArgumentError)
      expect do
        AceUdpProtoSpec.new('')
      end.to raise_error(AclArgumentError)
    end
  end
end

describe AceTcpProtoSpec do
  describe '#name_to_numer, #to_i' do
    it 'should be "49" by converting proto name "tacacs"' do
      atps = AceTcpProtoSpec.new('tacacs')
      expect(atps.number).to eq 49
      expect(atps.to_i).to eq 49
    end

    it 'should be error by converting unknown proto name "fuga"' do
      expect do
        AceTcpProtoSpec.new('fuga')
      end.to raise_error(AclArgumentError)
    end
  end

  describe 'class#valid_name?' do
    it 'should be true when valid tcp port name' do
      expect(AceTcpProtoSpec.valid_name?('daytime')).to be_truthy
    end

    it 'should be false when invalid tcp port name' do
      expect(AceTcpProtoSpec.valid_name?('snmp')).to be_falsey
    end
  end

  describe '#to_s' do
    tcp_port_data = <<~'EOL'
      bgp          Border Gateway Protocol (179)
      chargen      Character generator (19)
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
      aups = AceTcpProtoSpec.new(6_633)
      expect(aups.to_s).to be_aclstr('6633')
    end

    it 'should be error when not specified name/number' do
      expect do
        AceTcpProtoSpec.new
      end.to raise_error(AclArgumentError)
      expect do
        AceTcpProtoSpec.new('')
      end.to raise_error(AclArgumentError)
    end

    it 'should be error when out of range port number' do
      expect do
        AceTcpProtoSpec.new(65_536)
      end.to raise_error(AclArgumentError)

      expect do
        AceTcpProtoSpec.new(-1)
      end.to raise_error(AclArgumentError)
    end
  end
end

describe AceIpProtoSpec do
  describe '#name_to_numer' do
    it 'should be "88" by converting proto name "eigrp"' do
      aips = AceIpProtoSpec.new('eigrp')
      expect(aips.number).to eq 88
      expect(aips.to_i).to eq 88
    end

    it 'should be error by converting unknown proto name "foo"' do
      expect do
        AceIpProtoSpec.new('foo')
      end.to raise_error(AclArgumentError)
    end
  end

  describe 'class#valid_name?' do
    it 'should be true when valid tcp port name' do
      expect(AceIpProtoSpec.valid_name?('ospf')).to be_truthy
    end

    it 'should be false when invalid tcp port name' do
      expect(AceIpProtoSpec.valid_name?('daytime')).to be_falsey
    end
  end

  describe '#contains?' do
    before(:all) do
      @p_ip = AceIpProtoSpec.new('ip')
      @p_ip2 = AceIpProtoSpec.new('ip')
      @p_tcp = AceIpProtoSpec.new(6)
      @p_tcp2 = AceIpProtoSpec.new('tcp')
      @p_udp = AceIpProtoSpec.new(17)
      @p_udp2 = AceIpProtoSpec.new('udp')
      @p_esp = AceIpProtoSpec.new('esp')
    end

    it 'should be true, ip includes tcp/udp' do
      expect(@p_ip.contains?(@p_tcp)).to be_truthy
      expect(@p_ip.contains?(@p_udp)).to be_truthy
      expect(@p_ip.contains?(@p_ip2)).to be_truthy
    end

    it 'should be false, ip not includes esp' do
      expect(@p_ip.contains?(@p_esp)).to be_falsey
      expect(@p_esp.contains?(@p_ip)).to be_falsey
      expect(@p_esp.contains?(@p_tcp)).to be_falsey
      expect(@p_esp.contains?(@p_udp)).to be_falsey
    end

    it 'should be true, tcp/udp includes tcp/udp' do
      expect(@p_tcp.contains?(@p_tcp2)).to be_truthy
      expect(@p_udp.contains?(@p_udp2)).to be_truthy
    end

    it 'should be false, tcp/udp not includes ip/udp/tcp' do
      expect(@p_tcp.contains?(@p_ip)).to be_falsey
      expect(@p_tcp.contains?(@p_udp)).to be_falsey
      expect(@p_tcp.contains?(@p_esp)).to be_falsey
      expect(@p_udp.contains?(@p_ip)).to be_falsey
      expect(@p_udp.contains?(@p_tcp)).to be_falsey
      expect(@p_udp.contains?(@p_esp)).to be_falsey
    end
  end

  describe '#to_s' do
    ip_port_data = <<~'EOL'
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
      aups = AceIpProtoSpec.new(255)
      expect(aups.to_s).to be_aclstr('255')
    end

    it 'should be error when out of range port number' do
      expect do
        AceIpProtoSpec.new(256)
      end.to raise_error(AclArgumentError)

      expect do
        AceIpProtoSpec.new(-1)
      end.to raise_error(AclArgumentError)
    end

    it 'should be error when not specified name/number' do
      expect do
        AceIpProtoSpec.new
      end.to raise_error(AclArgumentError)
      expect do
        AceIpProtoSpec.new('')
      end.to raise_error(AclArgumentError)
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
