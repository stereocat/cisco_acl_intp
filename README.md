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

    gem 'cisco_acl_intp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cisco_acl_intp

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
