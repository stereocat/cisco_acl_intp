# CiscoAclIntp

CiscoAclIntp is a interpreter of Cisco IOS access list.

## Features Overview

CiscoAclIntp...

* can parse ACL types of below
  * Numbered ACL (standard/extended)
  * Named ACL (standard/extended)
* can parse almost ACL syntaxes.
  * can handle basic IPv4 acl (protocol ip/tcp/udp)
  * cannot handle IPv4 tcp-flags-qualifier, object-groups,
    and other qualifiers (dscp, ttl, tos, ...).
    These features are not implemented yet.
* cannot handle ipv6 ACL (not implemented yet)

## Installation

Add this line to your application's Gemfile:

    gem 'CiscoAclIntp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install CiscoAclIntp

## Usage

TODO: Write usage instructions here

