# -*- coding: utf-8 -*-
require 'spec_helper'

include CiscoAclIntp
AclContainerBase.disable_color

describe AceIpSpec do
  describe '#to_s' do
    it 'should be "192.168.15.15 0.0.7.6"' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.7.6'
      )
      ip.to_s.should be_aclstr('192.168.8.9 0.0.7.6')
    end

    it 'should be "any"' do
      ip = AceIpSpec.new(
        ipaddr: '0.0.0.0',
        wildcard: '255.255.255.255'
      )
      ip.to_s.should be_aclstr('any')
    end

    it 'should be "any" with full-bit wildcard mask' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '255.255.255.255'
      )
      ip.to_s.should be_aclstr('any')
    end

    it 'should be "any" with zero-ip' do
      ip = AceIpSpec.new(
        ipaddr: '0.0.0.0',
        wildcard: '0.0.7.6'
      )
      ip.to_s.should be_aclstr('any')
    end

    it 'should be "host 192.168.15.15"' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.0.0'
      )
      ip.to_s.should be_aclstr('host 192.168.15.15')
    end

    it 'should be "192.168.14.0 0.0.1.255" with netmask /23' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 23
      )
      ip.to_s.should be_aclstr('192.168.14.0 0.0.1.255')
    end

    it 'should be "any" with netmask /0' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 0
      )
      ip.to_s.should be_aclstr('any')
    end

    it 'should be "host 192.168.15.15" with netmask /32' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 32
      )
      ip.to_s.should be_aclstr('host 192.168.15.15')
    end

    it 'should be "host 192.168.15.15" in default' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15'
      )
      ip.to_s.should be_aclstr('host 192.168.15.15')
    end

    context 'Argument Error Case' do
      it 'raise error without ipaddr' do
        lambda do
          AceIpSpec.new(
            netmask: 32
          )
        end.should raise_error(AclArgumentError)
      end

      it 'raise error with invalid ipaddr' do
        lambda do
          AceIpSpec.new(
            ipaddr: '192.168.15.256'
          )
        end.should raise_error
        lambda do
          AceIpSpec.new(
            ipaddr: '192.168.250.3.3'
          )
        end.should raise_error
        lambda do
          AceIpSpec.new(
            ipaddr: '192,168.250.3'
          )
        end.should raise_error
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
