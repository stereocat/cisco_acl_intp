# frozen_string_literal: true

require 'spec_helper'

describe StandardAce do
  describe '#to_s' do
    context 'Normal case' do
      it 'should be permit action and set ip/wildcard' do
        sa = StandardAce.new(
          action: 'permit',
          src: { ipaddr: '192.168.15.15', wildcard: '0.0.7.6' }
        )
        expect(sa.to_s).to be_aclstr('permit 192.168.8.9 0.0.7.6')
      end

      it 'should be deny action and set ip/wildcard' do
        sa = StandardAce.new(
          action: 'deny',
          src: { ipaddr: '192.168.15.15', wildcard: '0.0.0.127' }
        )
        expect(sa.to_s).to be_aclstr('deny 192.168.15.0 0.0.0.127')
      end

      it 'should be able set with AceSrcDstSpec object' do
        asds = AceSrcDstSpec.new(
          ipaddr: '192.168.3.144', wildcard: '0.0.0.127'
        )
        sa = StandardAce.new(action: 'permit', src: asds)
        expect(sa.to_s).to be_aclstr('permit 192.168.3.128 0.0.0.127')
      end
    end

    context 'Argument error case' do
      it 'should be rased exception when :action not specified' do
        expect do
          StandardAce.new(
            src: { ipaddr: '192.168.3.3', wildcard: '0.0.0.127' }
          )
        end.to raise_error(AclArgumentError)
      end
    end
  end

  describe '#contains?' do
    before do
      @sa = StandardAce.new(
        action: 'permit',
        src: { ipaddr: '192.168.15.15', wildcard: '0.0.7.6' }
      )
      @ip_match = StandardAce.new(
        action: 'permit',
        src: { ipaddr: '192.168.9.11', netmask: 32 }
      )
      @ip_unmatch = StandardAce.new(
        action: 'permit',
        src: { ipaddr: '192.168.9.12', netmask: 32 }
      )
    end

    it 'shoud be true with match ip addr' do
      expect(@sa.contains?(@ip_match)).to be_truthy
    end

    it 'should be false with unmatch ip addr' do
      expect(@sa.contains?(@ip_unmatch)).to be_falsey
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
