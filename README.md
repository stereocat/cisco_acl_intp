# CiscoAclIntp
[![Gem Version](https://badge.fury.io/rb/cisco_acl_intp.png)](http://badge.fury.io/rb/cisco_acl_intp)
[![Build Status](https://travis-ci.org/stereocat/cisco_acl_intp.png?branch=master)](https://travis-ci.org/stereocat/cisco_acl_intp)
[![Dependency Status](https://gemnasium.com/stereocat/cisco_acl_intp.png)](https://gemnasium.com/stereocat/cisco_acl_intp)

CiscoAclIntp is a interpreter of Cisco IOS access control list (ACL).

## Features Overview

CiscoAclIntp can...

* parse ACL types of below
  * Numbered ACL (standard/extended)
  * Named ACL (standard/extended)
* parse almost ACL syntaxes.
  * basic IPv4 acl (protocol `ip`/`tcp`/`udp`)

CiscoAclIntp *CANNOT*...

* handle IPv4 tcp-flags-qualifier, object-groups, and other specific
  qualifiers (`dscp`, `ttl`, `tos`, ...).  These features are not
  implemented yet.
* handle IPv6 ACL (`ip access-list ipv6`) (not implemented yet)

Supports

* Ruby/1.9 or later. (Development and testing is being conducted in
  Ruby/2.0.0 and *NOT* supported Ruby/1.8.x)
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

Front-end of ACL Varidator is at
[github](https://github.com/stereocat/cisco_acl_web). It not only can
parse (with CLI tool, it can only parse), but also search for ACL(ACE).

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
