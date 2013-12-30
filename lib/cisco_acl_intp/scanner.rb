# -*- coding: utf-8 -*-
require 'strscan'

module CiscoAclIntp

  # Lexical analyzer (Scanner)
  class Scanner

    # Scan ACL from file to parse
    # @param [File] file File name
    # @return [Array] Scanned tokens array
    def scan_file(file)
      # queue
      q = []

      file.each_line do | each |
        q.concat(scan_one_line(each))
      end
      q.push [false, 'EOF']

      q
    end

    # Scan ACL from variable
    # @param [String] str Access list string
    # @return [Array] Scanned tokens array
    def scan_line(str)
      q = []

      @curr_line = ''
      @old_line = ''

      str.split(/$/).each do | each |
        each.chomp!
        # add word separator at end of line
        each.concat(' ')
        q.concat(scan_one_line(each))
      end
      q.push [false, 'EOF']

      q
    end

    # Scan ACL
    # @param [String] line Access list string
    # @return [Array] Scanned tokens array
    def scan_one_line(line)

      # queue
      q = []
      # STRING regexp
      strexp = '[a-zA-Z\d]\S*'

      s = StringScanner.new line
      until s.eos?

        ## TBD
        ## q.push (:TAG, value)
        ## value を scaned term (String) か symbol にするか。
        ## 文字としてどれも同一だとみなすのであれば symbol にするのが向いている?

        case

        when s.scan(/(?:remark)(.*)/)
          # named acl remark case
          q.push [:REMARK, s[1]]
        when s.scan(/(?:description)(.*)/)
          # object-group description
          q.push [:DESCRIPTION, s[1]]
        when s.scan(/\s*!.*$/), s.scan(/\s*#.*$/)
          ## "!/# comment" and whitespace line, NO-OP
          # puts "comment line :#{s[0]}" # for debug
        when s.scan(/\s+/), s.scan(/\A\s*\Z/)
          ## whitespace, NO-OP
          # q.push [:WHITESPACE, ""] # for debug
        when s.scan(/(?:access-list)\s+(\d+)\s/)
          aclnum = s[1].to_i
          if (1 <= aclnum && aclnum <= 99) ||
              (1300 <= aclnum && aclnum <= 1999)
            q.push [:NUMD_STD_ACL, aclnum]
          elsif (100 <= aclnum && aclnum <= 199) ||
              (2000 <= aclnum && aclnum <= 2699)
            q.push [:NUMD_EXT_ACL, aclnum]
          else
            q.push [:UNKNOWN_TOKEN, "access-list #{aclnum}"]
          end
        when s.scan(/(ip\s+access\-list)\s/)
          # Notice: word 'ip' conflicted:
          # 'ip access-list' and 'ip' as ip_proto
          q.push [:NAMED_ACL, s[1]]

          # reserved
        when s.scan(/(ipv6)\s/)
          q.push [:IPV6,  s[1]]

          # named-acl
          ## usually, acl-name is at last of line.
          ## not need /$/, /\Z/, /\s/ to separate term
        when s.scan(/(extended)\s+(#{strexp})/)
          q.push [:EXTENDED, s[1]]
          q.push [:STRING, s[2]]
        when s.scan(/(standard)\s+(#{strexp})/)
          q.push [:STANDARD, s[1]]
          q.push [:STRING, s[2]]

          # action
        when s.scan(/(permit)\s/)
          q.push [:PERMIT, s[1]]
        when s.scan(/(deny)\s/)
          q.push [:DENY,   s[1]]

          # dynamic_spec
        when s.scan(/(dynamic)\s+(#{strexp})\s/)
          q.push [:DYNAMIC, s[1]]
          q.push [:STRING,  s[2]]
        when s.scan(/(timeout)\s/)
          q.push [:TIMEOUT, s[1]]

          # tcp_flag
        when s.scan(/(established)\s/)
          q.push [:ESTABL,    s[1]]
        when s.scan(/(syn)\s/)
          q.push [:SYN,       s[1]]
        when s.scan(/(ack)\s/)
          q.push [:ACK,       s[1]]
        when s.scan(/(fin)\s/)
          q.push [:FIN,       s[1]]
        when s.scan(/(psh)\s/)
          q.push [:PSH,       s[1]]
        when s.scan(/(urg)\s/)
          q.push [:URG,       s[1]]
        when s.scan(/(rst)\s/)
          q.push [:RST,       s[1]]
        when s.scan(/([\+\-]syn)\s/)
          q.push [:PM_SYN,    s[1]]
        when s.scan(/([\+\-]ack)\s/)
          q.push [:PM_ACK,    s[1]]
        when s.scan(/([\+\-]fin)\s/)
          q.push [:PM_FIN,    s[1]]
        when s.scan(/([\+\-]psh)\s/)
          q.push [:PM_PSH,    s[1]]
        when s.scan(/([\+\-]urg)\s/)
          q.push [:PM_URG,    s[1]]
        when s.scan(/([\+\-]rst)\s/)
          q.push [:PM_RST,    s[1]]
        when s.scan(/(match-all)\s/)
          q.push [:MATCH_ALL, s[1]]
        when s.scan(/(match-any)\s/)
          q.push [:MATCH_ANY, s[1]]

          # ip_proto (convert to protocol number)
        when s.scan(/(ahp)\s/)
          q.push [:AHP,    s[1]]
        when s.scan(/(eigrp)\s/)
          q.push [:EIGRP,  s[1]]
        when s.scan(/(esp)\s/)
          q.push [:ESP,    s[1]]
        when s.scan(/(gre)\s/)
          q.push [:GRE,    s[1]]
        when s.scan(/(icmp)\s/)
          q.push [:ICMP,   s[1]]
        when s.scan(/(igmp)\s/)
          q.push [:IGMP,   s[1]]
        when s.scan(/(ipinip)\s/)
          q.push [:IPINIP, s[1]]
        when s.scan(/(ip)\s/)
          q.push [:IP,     s[1]]
        when s.scan(/(nos)\s/)
          q.push [:NOS,    s[1]]
        when s.scan(/(ospf)\s/)
          q.push [:OSPF,   s[1]]
        when s.scan(/(pcf)\s/)
          q.push [:PCF,    s[1]]
        when s.scan(/(pim)\s/)
          q.push [:PIM,    s[1]]
        when s.scan(/(tcp)\s/)
          q.push [:TCP,    s[1]]
        when s.scan(/(udp)\s/)
          q.push [:UDP,    s[1]]

          # other_qualifier
        when s.scan(/(fragments)\s/)
          q.push [:FRAGMENTS, s[1]]

          # logging
        when s.scan(/(log-input)\s/)
          q.push [:LOG_INPUT,  s[1]]
        when s.scan(/(log-update)\s/)
          q.push [:LOG_UPDATE, s[1]]
        when s.scan(/(log)\s/)
          q.push [:LOG,        s[1]]
        when s.scan(/(threshold)\s/)
          q.push [:THRESHOLD,  s[1]]

          # time_range_spec
        when s.scan(/(time-range)\s/)
          q.push [:TIME_RANGE, s[1]]

          # icmp_qualifier
        when s.scan(/(administratively-prohibited)\s/)
          q.push [:ADM_PROHIB,        s[1]]
        when s.scan(/(alternate-address)\s/)
          q.push [:ALT_ADDR,          s[1]]
        when s.scan(/(conversion-error)\s/)
          q.push [:CONV_ERR,          s[1]]
        when s.scan(/(dod-host-prohibited)\s/)
          q.push [:DOD_HOST_PROHIB,   s[1]]
        when s.scan(/(dod-net-prohibited)\s/)
          q.push [:DOD_NET_PROHIB,    s[1]]
        when s.scan(/(echo-reply)\s/)
          q.push [:ECHO_REPLY,        s[1]]
        when s.scan(/(echo)\s/)
          q.push [:ECHO,              s[1]]
        when s.scan(/(general-parameter-problem)\s/)
          q.push [:GEN_PARAM_PROB,    s[1]]
        when s.scan(/(host-isolated)\s/)
          q.push [:HOST_ISOL,         s[1]]
        when s.scan(/(mobile-redirect)\s/)
          q.push [:MOB_REDIR,         s[1]]
        when s.scan(/(net-redirect)\s/)
          q.push [:NET_REDIR,         s[1]]
        when s.scan(/(net-tos-redirect)\s/)
          q.push [:NET_TOS_REDIR,     s[1]]
        when s.scan(/(net-unreachable)\s/)
          q.push [:NET_UNREACH,       s[1]]
        when s.scan(/(network-unknown)\s/)
          q.push [:NET_UNKN,          s[1]]
        when s.scan(/(no-room-for-option)\s/)
          q.push [:NO_ROOM_OPT,       s[1]]
        when s.scan(/(option-missing)\s/)
          q.push [:OPT_MISSING,       s[1]]
        when s.scan(/(packet-too-big)\s/)
          q.push [:PKT_TOO_BIG,       s[1]]
        when s.scan(/(parameter-problem)\s/)
          q.push [:PARAM_PROB,        s[1]]
        when s.scan(/(port-unreachable)\s/)
          q.push [:PORT_UNREACH,      s[1]]
        when s.scan(/(precedence-unreachable)\s/)
          q.push [:PREC_UNREACH,      s[1]]
        when s.scan(/(protocol-unreachable)\s/)
          q.push [:PROT_UNREACH,      s[1]]
        when s.scan(/(host-precedence-unreachable)\s/)
          q.push [:HOST_PREC_UNREACH, s[1]]
        when s.scan(/(host-redirect)\s/)
          q.push [:HOST_REDIR,        s[1]]
        when s.scan(/(host-tos-redirect)\s/)
          q.push [:HOST_TOS_REDIR,    s[1]]
        when s.scan(/(host-unknown)\s/)
          q.push [:HOST_UNKN,         s[1]]
        when s.scan(/(host-unreachable)\s/)
          q.push [:HOST_UNREACH,      s[1]]
        when s.scan(/(information-reply)\s/)
          q.push [:INFO_REPLY,        s[1]]
        when s.scan(/(information-request)\s/)
          q.push [:INFO_REQ,          s[1]]
        when s.scan(/(mask-reply)\s/)
          q.push [:MASK_REPLY,        s[1]]
        when s.scan(/(mask-request)\s/)
          q.push [:MASK_REQ,          s[1]]
        when s.scan(/(reassembly-timeout)\s/)
          q.push [:REASS_TIMEOUT,     s[1]]
        when s.scan(/(redirect)\s/)
          q.push [:REDIR,             s[1]]
        when s.scan(/(router-advertisement)\s/)
          q.push [:ROUTER_ADV,        s[1]]
        when s.scan(/(router-solicitation)\s/)
          q.push [:ROUTER_SOL,        s[1]]
        when s.scan(/(source-quench)\s/)
          q.push [:SRC_QUENCH,        s[1]]
        when s.scan(/(source-route-failed)\s/)
          q.push [:SRC_ROUTE_FAIL,    s[1]]
        when s.scan(/(time-exceeded)\s/)
          q.push [:TIME_EXC,          s[1]]
        when s.scan(/(timestamp-reply)\s/)
          q.push [:TIME_REPLY,        s[1]]
        when s.scan(/(timestamp-request)\s/)
          q.push [:TIME_REQ,          s[1]]
        when s.scan(/(traceroute)\s/)
          q.push [:TRACERT,           s[1]]
        when s.scan(/(ttl-exceeded)\s/)
          q.push [:TTL_EXC,           s[1]]
        when s.scan(/(unreachable)\s/)
          q.push [:UNREACH,           s[1]]

          # ipv6 acl?
        when s.scan(/(beyond-scope)\s/)
          q.push [:BEYOND_SCOPE,  s[1]]
        when s.scan(/(destination-unreachable)\s/)
          q.push [:DEST_UNREACH,  s[1]]
        when s.scan(/(echo-request)\s/)
          q.push [:ECHO_REQUEST,  s[1]]
        when s.scan(/(flow-label)\s/)
          q.push [:FLOW_LABEL,    s[1]]
        when s.scan(/(mld-reduction)\s/)
          q.push [:MLD_REDUCTION, s[1]]
        when s.scan(/(mld-report)\s/)
          q.push [:MLD_REPORT,    s[1]]
        when s.scan(/(next-header)\s/)
          q.push [:NEXT_HEADER,   s[1]]
        when s.scan(/(parameter-option)\s/)
          q.push [:PARAM_OPTION,  s[1]]
        when s.scan(/(renum-command)\s/)
          q.push [:RENUM_CMD,     s[1]]
        when s.scan(/(renum-result)\s/)
          q.push [:RENUM_RES,     s[1]]
        when s.scan(/(renum-seq-number)\s/)
          q.push [:RENUM_SEQ_NR,  s[1]]
        when s.scan(/(router-renumbering)\s/)
          q.push [:ROUTER_RENUM,  s[1]]
        when s.scan(/(undetermined-transport)\s/)
          q.push [:UNDET_TRAN,    s[1]]
        when s.scan(/(nd-na)\s/)
          q.push [:ND_NA,     s[1]]
        when s.scan(/(nd-ns)\s/)
          q.push [:ND_NS,     s[1]]
        when s.scan(/(header)\s/)
          q.push [:HEADER,    s[1]]
        when s.scan(/(hop-limit)\s/)
          q.push [:HOP_LIMIT, s[1]]
        when s.scan(/(mld-query)\s/)
          q.push [:MLD_QUERY, s[1]]
        when s.scan(/(no-admin)\s/)
          q.push [:NO_ADMIN,  s[1]]
        when s.scan(/(no-route)\s/)
          q.push [:NO_ROUTE,  s[1]]
        when s.scan(/(routing)\s/)
          q.push [:ROUTING,   s[1]]
        when s.scan(/(sequence)\s/)
          q.push [:SEQUENCE,  s[1]]

          # precedence_qualifier
          ## 'network' token overwraped in 'object-group' and 'precedence'
        when s.scan(/(flash-override)\s/)
          q.push [:PREC_FLASH_OVERR, s[1]]
        when s.scan(/(precedence)\s/)
          q.push [:PRECEDENCE,    s[1]]
        when s.scan(/(critical)\s/)
          q.push [:PREC_CRITICAL, s[1]]
        when s.scan(/(flash)\s/)
          q.push [:PREC_FLASH,    s[1]]
        when s.scan(/(immediate)\s/)
          q.push [:PREC_IMMED,    s[1]]
        when s.scan(/(internet)\s/)
          q.push [:PREC_INET,     s[1]]
        when s.scan(/(priority)\s/)
          q.push [:PREC_PRIO,     s[1]]
        when s.scan(/(routine)\s/)
          q.push [:PREC_ROUTINE,  s[1]]
        when s.scan(/(network)\s/)
          q.push [:NETWORK,       s[1]]

          # tos_qualifier
        when s.scan(/(tos)\s/)
          q.push [:TOS,            s[1]]
        when s.scan(/(max-reliability)\s/)
          q.push [:TOS_MAX_REL,    s[1]]
        when s.scan(/(max-throughput)\s/)
          q.push [:TOS_MAX_THRPUT, s[1]]
        when s.scan(/(min-delay)\s/)
          q.push [:TOS_MIN_DELAY,  s[1]]
        when s.scan(/(min-monetary-cost)\s/)
          q.push [:TOS_MIN_MONET_COST, s[1]]
        when s.scan(/(normal)\s/)
          q.push [:TOS_NORMAL,     s[1]]

          # recursive_qualifier
        when s.scan(/(reflect)\s+(#{strexp})\s/)
          q.push [:REFLECT,  s[1]]
          q.push [:STRING,   s[2]]
        when s.scan(/(evaluate)\s+(#{strexp})\s/)
          q.push [:EVALUATE, s[1]]
          q.push [:STRING,   s[2]]

          # tcp_port_qualifier
        when s.scan(/(bgp)\s/)
          q.push [:BGP,         s[1]]
        when s.scan(/(chargen)\s/)
          q.push [:CHARGEN,     s[1]]
        when s.scan(/(cmd)\s/)
          q.push [:CMD,         s[1]]
        when s.scan(/(daytime)\s/)
          q.push [:DAYTIME,     s[1]]
        when s.scan(/(domain)\s/)
          q.push [:DOMAIN,      s[1]]
        when s.scan(/(drip)\s/)
          q.push [:DRIP,        s[1]]
        when s.scan(/(exec)\s/)
          q.push [:EXEC,        s[1]]
        when s.scan(/(finger)\s/)
          q.push [:FINGER,      s[1]]
        when s.scan(/(ftp-data)\s/)
          q.push [:FTP_DATA,    s[1]]
        when s.scan(/(ftp)\s/)
          q.push [:FTP,         s[1]]
        when s.scan(/(gopher)\s/)
          q.push [:GOPHER,      s[1]]
        when s.scan(/(hostname)\s/)
          q.push [:HOSTNAME,    s[1]]
        when s.scan(/(ident)\s/)
          q.push [:IDENT,       s[1]]
        when s.scan(/(irc)\s/)
          q.push [:IRC,         s[1]]
        when s.scan(/(klogin)\s/)
          q.push [:KLOGIN,      s[1]]
        when s.scan(/(kshell)\s/)
          q.push [:KSHELL,      s[1]]
        when s.scan(/(login)\s/)
          q.push [:LOGIN,       s[1]]
        when s.scan(/(lpd)\s/)
          q.push [:LPD,         s[1]]
        when s.scan(/(nntp)\s/)
          q.push [:NNTP,        s[1]]
        when s.scan(/(pim-auto-rp)\s/)
          q.push [:PIM_AUTO_RP, s[1]]
        when s.scan(/(pop2)\s/)
          q.push [:POP2,        s[1]]
        when s.scan(/(pop3)\s/)
          q.push [:POP3,        s[1]]
        when s.scan(/(smtp)\s/)
          q.push [:SMTP,        s[1]]
        when s.scan(/(tacacs)\s/)
          q.push [:TACACS,      s[1]]
        when s.scan(/(telnet)\s/)
          q.push [:TELNET,      s[1]]
        when s.scan(/(uucp)\s/)
          q.push [:UUCP,        s[1]]
        when s.scan(/(whois)\s/)
          q.push [:WHOIS,       s[1]]
        when s.scan(/(www)\s/)
          q.push [:WWW,         s[1]]

          # udp_port_qualifier
        when s.scan(/(biff)\s/)
          q.push [:BIFF,          s[1]]
        when s.scan(/(bootpc)\s/)
          q.push [:BOOTPC,        s[1]]
        when s.scan(/(bootps)\s/)
          q.push [:BOOTPS,        s[1]]
        when s.scan(/(dnsix)\s/)
          q.push [:DNSIX,         s[1]]
        when s.scan(/(isakmp)\s/)
          q.push [:ISAKMP,        s[1]]
        when s.scan(/(mobile-ip)\s/)
          q.push [:MOBILE_IP,     s[1]]
        when s.scan(/(nameserver)\s/)
          q.push [:NAMESERVER,    s[1]]
        when s.scan(/(netbios-dgm)\s/)
          q.push [:NETBIOS_DGM,   s[1]]
        when s.scan(/(netbios-ns)\s/)
          q.push [:NETBIOS_NS,    s[1]]
        when s.scan(/(netbios-ss)\s/)
          q.push [:NETBIOS_SS,    s[1]]
        when s.scan(/(non500-isakmp)\s/)
          q.push [:NON500_ISAKMP, s[1]]
        when s.scan(/(ntp)\s/)
          q.push [:NTP,           s[1]]
        when s.scan(/(pim-auto-rp)\s/)
          q.push [:PIM_AUTO_RP,   s[1]]
        when s.scan(/(rip)\s/)
          q.push [:RIP,           s[1]]
        when s.scan(/(snmp)\s/)
          q.push [:SNMP,          s[1]]
        when s.scan(/(snmptrap)\s/)
          q.push [:SNMPTRAP,      s[1]]
        when s.scan(/(syslog)\s/)
          q.push [:SYSLOG,        s[1]]
        when s.scan(/(tftp)\s/)
          q.push [:TFTP,          s[1]]
        when s.scan(/(who)\s/)
          q.push [:WHO,           s[1]]
        when s.scan(/(xdmcp)\s/)
          q.push [:XDMCP,         s[1]]

          # tcp/udp common qualifier
          ## overwrap token: icmp discard...
          ## overwrap token: icmp echo...
        when s.scan(/(discard)\s/)
          q.push [:DISCARD, s[1]]
        when s.scan(/(echo)\s/)
          q.push [:ECHO,    s[1]]
        when s.scan(/(sunrpc)\s/)
          q.push [:SUNRPC,  s[1]]
        when s.scan(/(talk)\s/)
          q.push [:TALK,    s[1]]
        when s.scan(/(time)\s/)
          q.push [:TIME,    s[1]]

          # dscp_rule
        when s.scan(/(dscp)\s/)
          q.push [:DSCP,    s[1]]
        when s.scan(/(af11)\s/)
          q.push [:AF11,    s[1]]
        when s.scan(/(af12)\s/)
          q.push [:AF12,    s[1]]
        when s.scan(/(af13)\s/)
          q.push [:AF13,    s[1]]
        when s.scan(/(af21)\s/)
          q.push [:AF21,    s[1]]
        when s.scan(/(af22)\s/)
          q.push [:AF22,    s[1]]
        when s.scan(/(af23)\s/)
          q.push [:AF23,    s[1]]
        when s.scan(/(af31)\s/)
          q.push [:AF31,    s[1]]
        when s.scan(/(af32)\s/)
          q.push [:AF32,    s[1]]
        when s.scan(/(af33)\s/)
          q.push [:AF33,    s[1]]
        when s.scan(/(af41)\s/)
          q.push [:AF41,    s[1]]
        when s.scan(/(af42)\s/)
          q.push [:AF42,    s[1]]
        when s.scan(/(af43)\s/)
          q.push [:AF43,    s[1]]
        when s.scan(/(cs1)\s/)
          q.push [:CS1,     s[1]]
        when s.scan(/(cs2)\s/)
          q.push [:CS2,     s[1]]
        when s.scan(/(cs3)\s/)
          q.push [:CS3,     s[1]]
        when s.scan(/(cs4)\s/)
          q.push [:CS4,     s[1]]
        when s.scan(/(cs5)\s/)
          q.push [:CS5,     s[1]]
        when s.scan(/(cs6)\s/)
          q.push [:CS6,     s[1]]
        when s.scan(/(cs7)\s/)
          q.push [:CS7,     s[1]]
        when s.scan(/(default)\s/)
          q.push [:DEFAULT, s[1]]
        when s.scan(/(ef)\s/)
          q.push [:EF,      s[1]]

          # option_qualifier
          ## 'traceroute' token overwrapped in 'icmp qualifier'
        when s.scan(/(option)\s/)
          q.push [:OPTION,       s[1]]
        when s.scan(/(add-ext)\s/)
          q.push [:ADD_EXT,      s[1]]
        when s.scan(/(any-options)\s/)
          q.push [:ANY_OPTS,     s[1]]
        when s.scan(/(com-security)\s/)
          q.push [:COM_SECURITY, s[1]]
        when s.scan(/(dps)\s/)
          q.push [:DPS,          s[1]]
        when s.scan(/(encode)\s/)
          q.push [:ENCODE,       s[1]]
        when s.scan(/(eool)\s/)
          q.push [:EOOL,         s[1]]
        when s.scan(/(ext-ip)\s/)
          q.push [:EXT_IP,       s[1]]
        when s.scan(/(ext-security)\s/)
          q.push [:EXT_SECURITY, s[1]]
        when s.scan(/(finn)\s/)
          q.push [:FINN,         s[1]]
        when s.scan(/(imitd)\s/)
          q.push [:IMITD,        s[1]]
        when s.scan(/(lsr)\s/)
          q.push [:LSR,          s[1]]
        when s.scan(/(mtup)\s/)
          q.push [:MTUP,         s[1]]
        when s.scan(/(mtur)\s/)
          q.push [:MTUD,         s[1]]
        when s.scan(/(no-op)\s/)
          q.push [:NO_OP,        s[1]]
        when s.scan(/(nsapa)\s/)
          q.push [:NSAPA,        s[1]]
        when s.scan(/(record-route)\s/)
          q.push [:RECORD_ROUTE, s[1]]
        when s.scan(/(route-alert)\s/)
          q.push [:ROUTER_ALERT, s[1]]
        when s.scan(/(sdb)\s/)
          q.push [:SDB,          s[1]]
        when s.scan(/(security)\s/)
          q.push [:SECURITY,     s[1]]
        when s.scan(/(ssr)\s/)
          q.push [:SSR,          s[1]]
        when s.scan(/(stream-id)\s/)
          q.push [:STREAM_ID,    s[1]]
        when s.scan(/(timestamp)\s/)
          q.push [:TIMESTAMP,    s[1]]
        when s.scan(/(ump)\s/)
          q.push [:UMP,          s[1]]
        when s.scan(/(visa)\s/)
          q.push [:VISA,         s[1]]
        when s.scan(/(zsu)\s/)
          q.push [:ZSU,          s[1]]

          # object-group
        when s.scan(/(object-group)\s+(network)\s+(#{strexp})\s/)
          # object-group header
          q.push [:OBJGRP,  s[1]]
          ## 'network' token overwraped in 'object-group' and 'precedence'
          q.push [:NETWORK, s[2]]
          q.push [:STRING,  s[3]]
        when s.scan(/(object-group)\s+(service)\s+(#{strexp})\s/)
          # object-group header
          q.push [:OBJGRP,  s[1]]
          q.push [:SERVICE, s[2]]
          q.push [:STRING,  s[3]]
        when s.scan(/(object-group)\s+(#{strexp})\s/)
          # object-group reference
          q.push [:OBJGRP,  s[1]]
          q.push [:STRING,  s[2]]
        when s.scan(/(tcp-udp)\s/)
          q.push [:TCPUDP, s[1]]
        when s.scan(/(source)\s/)
          q.push [:SOURCE, s[1]]
        when s.scan(/(group-object)\s/)
          q.push [:GRPOBJ, s[1]]

          # operator
        when s.scan(/(eq)\s/)
          q.push [:EQ,    s[1]]
        when s.scan(/(neq)\s/)
          q.push [:NEQ,   s[1]]
        when s.scan(/(gt)\s/)
          q.push [:GT,    s[1]]
        when s.scan(/(lt)\s/)
          q.push [:LT,    s[1]]
        when s.scan(/(range)\s/)
          q.push [:RANGE, s[1]]

          # ip_spec
          ## match "any-*", "host-*" at first (below)
        when s.scan(/(any)\s/)
          q.push [:ANY,  s[1]]
        when s.scan(/(host)\s/)
          q.push [:HOST, s[1]]

          # ip address
        when s.scan(/(\d+\.\d+\.\d+\.\d+)\s/)
          q.push [:IPV4_ADDR, s[1]]
        when s.scan(/(\d+\.\d+\.\d+\.\d+)(\/)(\d+)\s/)
          # 'ip/mask' notation
          q.push [:IPV4_ADDR, s[1]]
          q.push [:SLASH,     s[2]]
          q.push [:NUMBER,    s[3].to_i]

          # common tokens
        when s.scan(/(\d+)\s/)
          # number
          q.push [:NUMBER, s[1].to_i]
        when s.scan(/(#{strexp})/)
          # string
          q.push [:STRING, s[1]]
        else
          # not match
          q.push [:UNKNOWN_TOKEN, line]

        end # case

      end # while

      # end of string
      q.push [:EOS, nil]

      q
    end # def scan_one_line

  end # class Scanner

end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
