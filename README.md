# CiscoAclIntp
[![Gem Version](https://badge.fury.io/rb/cisco_acl_intp.png)](http://badge.fury.io/rb/cisco_acl_intp)
[![Build Status](https://travis-ci.org/stereocat/cisco_acl_intp.png?branch=master)](https://travis-ci.org/stereocat/cisco_acl_intp)
[![Dependency Status](https://gemnasium.com/stereocat/cisco_acl_intp.png)](https://gemnasium.com/stereocat/cisco_acl_intp)
[![Coverage Status](https://coveralls.io/repos/stereocat/cisco_acl_intp/badge.png?branch=master)](https://coveralls.io/r/stereocat/cisco_acl_intp?branch=master)

CiscoAclIntp is a interpreter of Cisco IOS access control list (ACL).

## Features Overview

CiscoAclIntp can...

* parse ACL types of below
  * Numbered ACL (standard/extended)
  * Named ACL (standard/extended)
* parse almost ACL syntax.
  * basic IPv4 acl (protocol `ip`/`tcp`/`udp`)

CiscoAclIntp *CANNOT*...

* handle IPv4 tcp-flags-qualifier, object-groups, and other specific
  qualifiers (`dscp`, `ttl`, `tos`, ...).  These features are not
  implemented yet.
* handle IPv6 ACL (`ip access-list ipv6`) (not implemented yet)

Supports

* Ruby/2.0.0 or later. (Development and testing is being conducted in
  Ruby/2.0.0 and 2.1.1. It does *NOT* support Ruby/1.8.x and 1.9.x)
* Racc/1.4.9 or later.

## Installation

Add this line to your application's Gemfile:

    gem 'cisco_acl_intp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cisco_acl_intp

## Sample Application

### ACL Validator

#### Usage

One of application using CiscoAclIntp is in `tools/check_acl.rb`.
The script works as ACL validator.  It reads a ACL file, parse it with
CiscoAclIntp parser and output parser results.

In directory `acl_examples`, there are some Cisco IOS ACL sample
files. Run `check_acl.rb` with ACL sample files, like below.

```
$ ruby tools/check_acl.rb -c term -f acl_examples/err-acl.txt
--------------------
in acl: 100, line: 6, near value: udp, (token: "udp")
in acl: 100, line: 8, near value: 100, (token: NUMBER)
in acl: 100, line: 11, Wrong protocol number: 256
in acl: 100, line: 14, near value: hoge, (token: error)
in acl: FA8-OUT, line: 4, Wrong protocol number: 65536
in acl: FA8-OUT, line: 7, Provided wildcard mask failed validation: 0.0.240.256 is invalid (IPv4 octets should be between 0 and 255).
in acl: FA8-OUT, line: 13, near value: up, (token: error)
--------------------
acl name : 1
access-list 1 permit 192.168.0.0 0.0.255.255
access-list 1 deny any log
acl name : 100
access-list 100 remark General Internet Access
access-list 100 permit icmp any any
access-list 100 permit ip 192.168.0.0 0.0.255.255 any
access-list 100 permit tcp any host 210.197.74.200
access-list 100 remark !wrong acl number!
access-list 100 remark !------cleared------!
access-list 100 remark !wrong header! caccess-list
access-list 100 remark !------cleared------!
access-list 100 permit 41 any host 192.88.99.1
access-list 100 remark !wrong ip proto number!
access-list 100 !! error !! 192.88.99.1
access-list 100 remark !------cleared------!
access-list 100 remark !wrong ip proto!
access-list 100 !! error !! 192.88.99.1
access-list 100 remark !------cleared------!
access-list 100 permit ip any host 192.88.99.1
access-list 100 remark others
access-list 100 permit tcp any eq 0 any eq 0
access-list 100 permit udp any eq 0 any eq 0
access-list 100 deny ip any any log
acl name : 10
access-list 10 !! error !! ntp
acl name : 110
access-list 110 remark SPLIT_VPN
access-list 110 permit ip 192.168.0.0 0.0.255.255 any
acl name : FA8-OUT
ip access-list extended FA8-OUT
 deny udp any any eq bootpc
 deny udp any any eq bootps
 remark !argment error! 65536
 !! error !! 65536
 remark !------cleared------!
 remark !argment error! 255 => 256
 !! error !! 80
 remark !------cleared------!
 remark network access-list remark!!
 permit tcp any any established
 deny tcp any any syn rst
 remark !syntax error! tcp -> tp (typo)
 !! error !! hoge
 remark !------cleared------!
 permit ip any any log
acl name : remote-ipv4
ip access-list standard remote-ipv4
 permit 192.168.0.0 0.0.255.255
 remark standard access-list last deny!?
 deny any log
$
```

By putting `-c` (`--color`) option, `check_acl.rb` outputs
**color-coded ACL** according to type of each word. It can parse
multiple ACLs at the same time. In addition, in the case of the
parsing of a ACL that contains errors, CiscoAclIntp parser outputs
corresponding error messages. Please try to run using sample ACL file,
`acl_examples/err-acl.txt`, that contains some kind of errors.

You can get short usage with `-h` option. If it runs without `-f`
(`--file`) option, it reads ACLs from standard input.

#### Codes

```ruby
require 'optparse'
require 'cisco_acl_intp'

## CUT: option handling

parser = CiscoAclIntp::Parser.new(popts)

# read acl from file or STDIN
if opts[:file]
  parser.parse_file opts[:file]
else
  parser.parse_file $stdin
end

# print acl data
aclt = parser.acl_table
aclt.each do |name, acl|
  puts "acl name : #{name}"
  puts acl.to_s
end
```

In the script, generate `CiscoAclIntp::Parser` instance and it reads
ACLs from a file (or `$stdin`). The `parser` instance generate ACL
objects (as Hash table of ACL name and ACL objects). An element of the
table is "ACL object". "ACL object" is build by ACL components. For
example, source/destination address obj, action obj, tcp/udp protocol
obj,... See more detail in documents (see also, Documents section)

### ACL Varidator Web Frontend

[Web front-end of ACL Varidator](https://github.com/stereocat/cisco_acl_web)
is at my github repository. It not only can parse (with CLI tool, it
can only parse), but also search for ACL(ACE).

## ACL operation as IP/Port set operation
### Overview

A CIDR-IP-Subnet, IP address with wildcard mask, TCP/UDP port
numbere(s) with operator (`any`, `eq`, `neq`, `lt`, `gt`, `range`),
these are set of IPs and/or ports. In CiscoAclIntp, `contains?`
methods are implemented some ACL/ACE class. It is a set operation
method of IP address and TCP/UDP port (to check set inclusion
relation).

Example:
```ruby
src = AceSrcDstSpec.new(
  ipaddr: '192.168.15.15', wildcard: '0.0.7.6',
  operator: 'gt', port: AceTcpProtoSpec.new(32_767)
)
dst = AceSrcDstSpec.new(
  ipaddr: '192.168.30.3', wildcard: '0.0.0.0',
  operator: 'range',
  begin_port: AceTcpProtoSpec.new(1_024),
  end_port: AceTcpProtoSpec.new(65_535)
)

# permit tcp 192.168.15.15 0.0.7.6 gt 32767 host 192.168.30.3 range 1024 65535
ace = ExtendedAce.new(
  action: 'permit', protocol: 'tcp', src: src, dst: dst
)

ace.contains?(
  protocol: 'tcp',
  src_operator: :eq, src_ip: '192.168.9.11', src_port: 51234
)
#=> true
```

### IP Addr Operation

See `NetAddr::CIDR#matches?` for CIDR subnet operation and
`NetAddr::CIDR#contains?` for IP with wildcard mask.

### Port Operation

In below table, "P" column is the argument of `#contains?`,
and operators at table header are receiver of `#contains?`.
The table shows case patterns with `port_X.contains?(port_P)`.
(`port_X` is a instance of `AceUnaryOpBase`
and it has port match operator and port number information.)

| P          | strict_any | any  | eq X   | neq X  | lt X   | gt X   | range X1 X2   |
|------------|------------|------|--------|--------|--------|--------|---------------|
| strict_any | true       | true | false  | false  | false  | false  | false         |
| any        | true       | true | false  | false  | false  | false  | X1=0 and X2=65535 |
| eq P       | false      | true | P = X  | P != X | P < X  | X < P  | X1 <= P <= X2 |
| neq P      | false      | true | false  | P = X  | P = X = 65535 | P = X = 0 | (P=X1=0 and X2=65535) or (X1=0 and P=X2=65535) |
| lt P       | false      | true | false  | P <= X | P <= X | false   | X1 = 0 and P < X2 |
| gt P       | false      | true | false  | X <= P | false  | X <= P  | X1 < P and X2 = 65535 |
| range P1 P2| false      | true | false  | P2 < X or X < P1 | P2 < X | X < P1 | X1 <= P1 and P2 <= X2 |


For example,`[gt X].contains?([eq P])` will be `true` if port `X < P`.
It means the ACL `[gt X]` permit (or deny) the flow `[eq P]`.
You can search ACEs which matches a flows specified by search conditions.

`:strict_any` is a special operator to search acl, the operator is
matches only `:any` operator.

## Documents

* [API document generated with YARD](http://rubydoc.info/gems/cisco_acl_intp/)

It can generate documents with YARD.

    $ rake yard

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
