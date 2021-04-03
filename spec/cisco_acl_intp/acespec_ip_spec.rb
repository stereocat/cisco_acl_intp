# frozen_string_literal: true

require 'spec_helper'

describe AceIpSpec do
  describe '#==' do
    before(:all) do
      @ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.3.255'
      )
      @ip1 = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.3.255'
      )
      @ip2 = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 22
      )
      @ip3 = AceIpSpec.new(
        ipaddr: '192.168.15.13',
        netmask: 22
      )
      @ip4 = AceIpSpec.new(
        ipaddr: '192.168.15.0',
        wildcard: '0.0.3.255'
      )
      @ip5 = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.1.255'
      )
    end

    it 'should be true same ip and same wildcard' do
      expect(@ip == @ip1).to be_truthy
    end

    it 'should be true same ip and same wildcard/netmask' do
      expect(@ip1 == @ip2).to be_truthy
    end

    it 'should be false different ip and same netmask' do
      expect(@ip2 == @ip3).to be_falsey
    end

    it 'should be false different ip and same wildcard' do
      expect(@ip1 == @ip4).to be_falsey
    end

    it 'should be false same ip and different wildcard' do
      expect(@ip1 == @ip5).to be_falsey
    end

    it 'should be true ANY object' do
      ip1 = AceIpSpec.new(ipaddr: 'any')
      ip2 = AceIpSpec.new(ipaddr: '0.0.0.0', wildcard: '255.255.255.255')
      ip3 = AceIpSpec.new(ipaddr: '0.0.0.0', netmask: 0)
      expect(ip1 == ip2).to be_truthy
      expect(ip2 == ip3).to be_truthy
      expect(ip3 == ip1).to be_truthy
    end
  end

  describe '#netmask, #wildcard' do
    it 'should be converted wildcard/netmask' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.31.255'
      )
      expect(ip.netmask).to eq 19
      expect(ip.wildcard).to eq '0.0.31.255'
    end

    it 'should not be converted wildcard/netmask' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.3.5.0'
      )
      expect(ip.netmask).to be_nil
      expect(ip.wildcard).to eq '0.3.5.0'
    end
  end

  describe '#contains?' do
    before do
      @ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 24
      )
    end

    it 'should be true when subnet is contained' do
      expect(@ip.contains?('192.168.15.3/25')).to be_truthy
    end

    it 'should be true when same subnet' do
      expect(@ip.contains?('192.168.15.3/24')).to be_truthy
    end

    it 'should be false when larger subnet' do
      expect(@ip.contains?('192.168.15.3/23')).to be_falsey
    end

    it 'should be false with not related block' do
      expect(@ip.contains?('192.168.16.3/24')).to be_falsey
    end
  end

  describe '#to_s' do
    it 'should be "192.168.15.15 0.0.7.6"' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.7.6'
      )
      expect(ip.to_s).to be_aclstr('192.168.8.9 0.0.7.6')
    end

    it 'should be "any" with any alias' do
      ip = AceIpSpec.new(ipaddr: 'any')
      expect(ip.to_s).to be_aclstr('any')
    end

    it 'should be "any"' do
      ip = AceIpSpec.new(
        ipaddr: '0.0.0.0',
        wildcard: '255.255.255.255'
      )
      expect(ip.to_s).to be_aclstr('any')
    end

    it 'should be "any" with full-bit wildcard mask' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '255.255.255.255'
      )
      expect(ip.to_s).to be_aclstr('any')
    end

    it 'should be "any" with zero-ip' do
      ip = AceIpSpec.new(
        ipaddr: '0.0.0.0',
        wildcard: '0.0.7.6'
      )
      expect(ip.to_s).to be_aclstr('any')
    end

    it 'should be "host 192.168.15.15"' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        wildcard: '0.0.0.0'
      )
      expect(ip.to_s).to be_aclstr('host 192.168.15.15')
    end

    it 'should be "192.168.14.0 0.0.1.255" with netmask /23' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 23
      )
      expect(ip.to_s).to be_aclstr('192.168.14.0 0.0.1.255')
    end

    it 'should be "any" with netmask /0' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 0
      )
      expect(ip.to_s).to be_aclstr('any')
    end

    it 'should be "host 192.168.15.15" with netmask /32' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15',
        netmask: 32
      )
      expect(ip.to_s).to be_aclstr('host 192.168.15.15')
    end

    it 'should be "host 192.168.15.15" in default' do
      ip = AceIpSpec.new(
        ipaddr: '192.168.15.15'
      )
      expect(ip.to_s).to be_aclstr('host 192.168.15.15')
    end

    context 'Argument Error Case' do
      it 'raise error without ipaddr' do
        expect do
          AceIpSpec.new(
            netmask: 32
          )
        end.to raise_error(AclArgumentError)
      end

      it 'raise error with invalid ipaddr' do
        expect do
          AceIpSpec.new(
            ipaddr: '192.168.15.256'
          )
        end.to raise_error
        expect do
          AceIpSpec.new(
            ipaddr: '192.168.250.3.3'
          )
        end.to raise_error
        expect do
          AceIpSpec.new(
            ipaddr: '192,168.250.3'
          )
        end.to raise_error
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
