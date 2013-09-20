# -*- coding: utf-8 -*-

require 'spec_helper'

include CiscoAclIntp
AclContainerBase::disable_color

describe StandardAce do
  describe "#to_s" do
    context "Normal case" do

      it 'should be permit action and set ip/wildcard' do
        sa = StandardAce.new(
          :action => 'permit',
          :src => { :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6' }
        )
        sa.to_s.should be_aclstr("permit 192.168.8.9 0.0.7.6")
      end

      it 'should be deny action and set ip/wildcard' do
        sa = StandardAce.new(
          :action => 'deny',
          :src => { :ipaddr => '192.168.15.15', :wildcard => '0.0.0.127' }
        )
        sa.to_s.should be_aclstr("deny 192.168.15.0 0.0.0.127")
      end

      it 'should be able set with AceSrcDstSpec object' do
        asds = AceSrcDstSpec.new(
          :ipaddr => '192.168.3.144', :wildcard => '0.0.0.127'
        )
        sa = StandardAce.new( :action => 'permit', :src => asds )
        sa.to_s.should be_aclstr("permit 192.168.3.128 0.0.0.127")
      end
    end

    context "Argument error case" do

      it 'should be rased exception when :action not specified' do
        lambda {
          sa = StandardAce.new(
            :src => { :ipaddr => '192.168.3.3', :wildcard => '0.0.0.127' }
          )
        }.should raise_error(AclArgumentError)
      end

    end
  end

  describe "#matches" do
    before do
      @sa = StandardAce.new(
        :action => 'permit',
        :src => { :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6' }
      )
      @ip_match = '192.168.9.11'
      @ip_unmatch = '192.168.9.12'
    end

    it 'shoud be true with match ip addr' do
      @sa.matches?( :src_ip => @ip_match ).should be_true
    end

    it 'should be false with unmatch ip addr' do
      @sa.matches?( :src_ip => @ip_unmatch ).should be_false
    end

    it 'should raise error when not specified ip_src' do
      lambda {
        @sa.matches?( :dst_ip => @ip_match )
      }.should raise_error(AclArgumentError)
    end
  end
end

describe ExtendedAce do
  describe "#to_s" do
    context "Normal case" do
      before do
        @src = AceSrcDstSpec.new(
          :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6' 
        )
        @dst = AceSrcDstSpec.new(
          :ipaddr => '192.168.30.3', :wildcard => '0.0.0.0',
          :operator => 'range',
          :port1 => AceTcpProtoSpec.new( :number => 1024 ),
          :port2 => AceTcpProtoSpec.new( :number => 65535)
        )
      end

      it 'should be protocol tcp, action permit' do
        ea = ExtendedAce.new(
          :action => 'permit',
          :protocol => 'tcp', :src => @src, :dst => @dst
        )
        ea.to_s.should be_aclstr("permit tcp 192.168.8.9 0.0.7.6 host 192.168.30.3 range 1024 65535")
      end

      it 'should be protocol tcp, action deny' do
        ea = ExtendedAce.new(
          :action => 'deny',
          :protocol => 'tcp', :src => @src, :dst => @dst
        )
        ea.to_s.should be_aclstr("deny tcp 192.168.8.9 0.0.7.6 host 192.168.30.3 range 1024 65535")
      end
    end

    context "Argument error case" do
      before do
        @src = AceSrcDstSpec.new(
          :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6' 
        )
        @dst = AceSrcDstSpec.new(
          :ipaddr => '192.168.30.3', :wildcard => '0.0.0.0',
          :operator => 'range',
          :port1 => AceTcpProtoSpec.new( :number => 1024 ),
          :port2 => AceTcpProtoSpec.new( :number => 65535)
        )
      end

      it 'should be rased exception when :action not specified' do
        lambda {
          ea = ExtendedAce.new(
            :protocol => 'tcp', :src => @src, :dst => @dst
          )
        }.should raise_error(AclArgumentError)
      end

      it 'should be rased exception when :protocol not specified' do
        lambda {
          ea = ExtendedAce.new(
            :action => 'deny',
            :src => @src, :dst => @dst
          )
        }.should raise_error(AclArgumentError)
      end

      it 'should be rased exception when :src not specified' do
        lambda {
          ea = ExtendedAce.new(
            :action => 'deny',
            :protocol => 'tcp', :dst => @dst
          )
        }.should raise_error(AclArgumentError)
      end

      it 'should be rased exception when :dst not specified' do
        lambda {
          ea = ExtendedAce.new(
            :action => 'deny',
            :protocol => 'tcp', :src => @src
          )
        }.should raise_error(AclArgumentError)
      end
    end
  end

  describe "#matches?" do
    context "tcp src/dst ip/port full spec test" do
      before do
        src = AceSrcDstSpec.new(
          :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6',
          :operator => 'gt',
          :port1 => AceTcpProtoSpec.new( :number => 32767 )
        )
        dst = AceSrcDstSpec.new(
          :ipaddr => '192.168.30.3', :wildcard => '0.0.0.0',
          :operator => 'range',
          :port1 => AceTcpProtoSpec.new( :number => 1024 ),
          :port2 => AceTcpProtoSpec.new( :number => 65535)
        )
        @ea = ExtendedAce.new(
          :action => 'permit',
          :protocol => 'tcp', :src => src, :dst => dst
        )
      end # before

      #----- begin code generation -----#

      ## generate test pattern data
      protocol_match = 'tcp'
      protocol_unmatch = 'udp'
      src_ip_match = '192.168.9.11'
      src_ip_unmatch = '192.168.9.12'
      src_port_match = 32768
      src_port_unmatch = 8080
      dst_ip_match = '192.168.30.3'
      dst_ip_unmatch = '192.168.30.4'
      dst_port_match = 3366
      dst_port_unmatch = 100

      codes = []
      tests = []
      bit = 5
      test_data = [
        :dst_port,
        :dst_ip,
        :src_port,
        :src_ip,
        :protocol
      ]
      for num in 0..2**bit-1 do
        opts = {}
        flag = 1
        for b in 0..bit-1 do
          pstr = num & flag == 0 ? "_match" : "_unmatch"
          str = test_data[b].to_s.concat( pstr )
          # puts "#{num}, #{b}, #{flag} #{test_data[b]} => #{str}"
          opts[ test_data[b] ] = eval "#{ str }"
          flag = flag << 1
        end
        tests.push(
          :opts => opts,
          :res  => num > 0 ? false : true
        )
      end

      tests.each do | each |
        codes.push <<"EOC"
      it 'should be #{ each[:res] }, when #{each[:opts][:protocol] };#{ each[:opts][:src_ip] }/#{ each[:opts][:src_port]} > #{ each[:opts][:dst_ip] }/#{ each[:opts][:dst_port] }' do
        @ea.matches?( #{ each[:opts].to_s } ).should be_#{ each[:res] }
      end # it
EOC
      end # tests.each

      eval codes.join

      #----- end code generation -----#

    end # context full spec test

    context 'ANY ip/port port exists case' do
      before do
        ip_any = AceIpSpec.new(
          :ipaddr => '0.0.0.0', :wildcard => '255.255.255.255'
        )
        port_any = AcePortSpec.new( :operator => 'any' )

        src_ip = AceIpSpec.new(
          :ipaddr => '192.168.15.15', :wildcard => '0.0.7.6'
        )
        src_port = AcePortSpec.new(
          :operator => 'gt',
          :port1 => AceTcpProtoSpec.new( :number => 32767 )
        )

        dst_ip = AceIpSpec.new(
          :ipaddr => '192.168.30.3', :wildcard => '0.0.0.0'
        )
        dst_port = AcePortSpec.new(
          :operator => 'range',
          :port1 => AceTcpProtoSpec.new( :number => 1024 ),
          :port2 => AceTcpProtoSpec.new( :number => 65535)
        )

        @src0 = AceSrcDstSpec.new( :ip_spec => src_ip, :port_spec => src_port )
        @src1 = AceSrcDstSpec.new( :ip_spec => ip_any, :port_spec => src_port )
        @src2 = AceSrcDstSpec.new( :ip_spec => src_ip, :port_spec => port_any )
        # @src3 = AceSrcDstSpec.new( :ip_spec => ip_any, :port_spec => port_any )
        @dst0 = AceSrcDstSpec.new( :ip_spec => dst_ip, :port_spec => dst_port )
        @dst1 = AceSrcDstSpec.new( :ip_spec => ip_any, :port_spec => dst_port )
        @dst2 = AceSrcDstSpec.new( :ip_spec => dst_ip, :port_spec => port_any )
        # @dst3 = AceSrcDstSpec.new( :ip_spec => ip_any, :port_spec => port_any )

        @src_ip_match = '192.168.9.11'
        @src_ip_unmatch = '192.168.9.12'
        @src_port_match = 32768
        @src_port_unmatch = 8080
        @dst_ip_match = '192.168.30.3'
        @dst_ip_unmatch = '192.168.30.4'
        @dst_port_match = 3366
        @dst_port_unmatch = 100
      end

      it 'should be true when any source ip' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src1, :dst => @dst0
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_true
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_unmatch, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_true
      end

      it 'should be false when any source ip and unmatch port' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src1, :dst => @dst0
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_unmatch,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_false
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_unmatch, :src_port => @src_port_unmatch,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_false
      end

      it 'should be true when any source port' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src2, :dst => @dst0
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_true
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_unmatch,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_true
      end

      it 'should be false when any source port and unmatch ip' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src2, :dst => @dst0
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_unmatch, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_false
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_unmatch, :src_port => @src_port_unmatch,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_false
      end

      it 'should be true when any destination ip' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src0, :dst => @dst1
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_true
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_unmatch, :dst_port => @dst_port_match
        ).should be_true
      end

      it 'should be false when any destination ip and unmatch port' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src0, :dst => @dst1
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_unmatch
        ).should be_false
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_unmatch, :dst_port => @dst_port_unmatch
        ).should be_false
      end

      it 'should be true when any destination port' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src0, :dst => @dst2
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_match
        ).should be_true
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_match, :dst_port => @dst_port_unmatch
        ).should be_true
      end

      it 'should be false when any destination port and unmatch ip' do
        ea = ExtendedAce.new(
          :action => 'permit', :protocol => 'tcp',
          :src => @src0, :dst => @dst2
        )
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_unmatch, :dst_port => @dst_port_match
        ).should be_false
        ea.matches?( :protocol => "tcp",
          :src_ip => @src_ip_match, :src_port => @src_port_match,
          :dst_ip => @dst_ip_unmatch, :dst_port => @dst_port_unmatch
        ).should be_false
      end

    end # context exists any ip/port

  end # describe matches?

end # describe ExtendedAce

describe RemarkAce do
  describe "#to_s" do
    it 'should be remark string' do
      rmk = RemarkAce.new("  foo-bar _ baz @@ COMMENT")
      rmk.to_s.should == " remark foo-bar _ baz @@ COMMENT"
    end
  end
  describe "#matches?" do
    it 'should be always false' do
      rmk = RemarkAce.new("asdfjklj;")
      rmk.matches?(
        :src_ip => '192.168.4.4', :dst_ip => '172.30.240.33'
      ).should be_false
      # with empty argments
      rmk.matches?.should be_false
    end
  end
end

describe EvaluateAce do
  describe "#to_s" do
    it 'should be evaluate term' do
      evl = EvaluateAce.new(
        :recursive_name => "foobar_baz"
      )
      evl.to_s.should be_aclstr( "evaluate foobar_baz" )
    end

    it 'raise error if not specified recursive name' do
      lambda {
        evl = EvaluateAce.new(
          :number => 30
        )
      }.should raise_error(AclArgumentError)
    end
  end
  describe "#matches?" do
    it 'should be always false (Now, not implemented yet)' do
      evl = EvaluateAce.new(
        :recursive_name => "asdf_0-98"
      )
      evl.matches?(
        :src_ip => '192.168.4.4', :dst_ip => '172.30.240.33'
      ).should be_false
      # with empty argments
      evl.matches?.should be_false
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
