# -*- coding: utf-8 -*-

require 'cisco_acl_intp/ace-srcdst'

module CiscoAclIntp

  # Access control entry base model
  class AceBase < AclContainerBase

    # @param [Integer] value ACL sequence number
    # @return [Integer]
    attr_accessor :seq_number

    # Number used when ACE does not has sequence number
    NO_SEQ_NUMBER = -1

    # Constructor
    # @param [Hash] opts
    # @option opts [Integer] :number Sequence number
    # @return [AceBase]
    def initialize(opts)
      if opts[:number]
        @seq_number = opts[:number]
      else
        @seq_number = NO_SEQ_NUMBER
      end
    end

    # Check this object has sequence number
    # @return [Boolean]
    def has_seq_number?
      @seq_number > NO_SEQ_NUMBER
    end

    # @param [AceBase] other RHS object
    # @return [Integer] Compare with protocol/port number
    def <=>(other)
      @seq_number <=> other.seq_number
    end

    # @param [AceBase] other RHS object
    # @return [Boolean]
    # @abstract
    def ==(other)
    end

    # Search matched ACE
    # @param [Hash] opts Options (target packet info)
    # @return [Boolean] Matched or not
    # @abstract
    def matches?(opts)
      false
    end
  end

  # Remark entry container
  class RemarkAce < AceBase

    # @param [String] value Comment string
    # @return [String]
    attr_accessor :comment

    # Constructor
    # @param [String] str Comment string
    # @return [RemarkAce]
    def initialize(str)
      @comment = str.strip
      @seq_number = NO_SEQ_NUMBER # remark does not takes line number
    end

    # @return [Boolean] Compare with comment string
    def ==(other)
      @comment == other.comment
    end

    # Generate string for Cisco IOS access list
    # @return [String] Comment string
    def to_s
      sprintf ' remark %s', c_rmk(@comment.to_s)
    end

    # Search matched ACE
    # @param [Hash] opts Options
    # return [Boolean] false, Remark does not match anithyng.
    def matches?(opts = nil)
      false
    end
  end

  # Evaluate entry container
  class EvaluateAce < AceBase

    # @param [String] value Recutsive entry name
    # @return [String]
    attr_accessor :recursive_name

    # Constructor
    # @param [Hash] opts Options
    # @option opts [Integer] :number Sequence number
    # @option opts [String] :recursive_name Recursive entry name
    # @raise [AclArgumentError]
    # @return [EvaluateAce]
    def initialize(opts)
      super

      if opts[:recursive_name]
        @recursive_name = opts[:recursive_name]
      else
        fail AclArgumentError, 'name not specified'
      end
    end

    # @return [Boolean] Compare with recursive entry name
    def ==(other)
      @recursive_name == other.recursive_name
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      sprintf 'evaluate %s', c_name(@recursive_name)
    end

    # Search matched ACE
    # @param [Hash] opts Options
    # return [Boolean] false, Recursive does not implemented yet
    def matches?(opts = nil)
      false
    end
  end

  # ACE for standard access list
  class StandardAce < AceBase

    # @param [String] value Action
    # @return [String]
    attr_accessor :action

    # @param [AceSrcDstSpec] value Source spec object
    # @return [AceSrcDstSpec]
    attr_accessor :src_spec

    # @param [AceLogSpec] value Log spec object
    # @return [AceLogSpec]
    attr_accessor :log_spec

    # Constructor
    # @param [Hash] opts Options
    # @option opts [Integer] :number Sequence number
    # @option opts [String] :action Action (permit/deny)
    # @option opts [AceSrcDstSpec] :src Source spec object
    # @option opts [Hash] :src Source spec parmeters
    # @option opts [AceLogSpec] :log Log spec object
    # @raise [AclArgumentError]
    # @return [StandardAce]
    def initialize(opts)
      super

      if opts[:action]
        @action = opts[:action]
      else
        fail AclArgumentError, 'Not specified action'
      end

      if opts[:src]
        case opts[:src]
        when Hash
          @src_spec = AceSrcDstSpec.new opts[:src]
        when AceSrcDstSpec
          @src_spec = opts[:src]
        else
          fail AclArgumentError, 'src spec: unknown class'
        end
      else
        fail AclArgumentError, 'Not specified src spec'
      end

      @log_spec = opts[:log] || nil
    end

    # @return [Boolean]
    def ==(other)
      @action == other.action && @src_spec == other.src_spec
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      sprintf(
        ' %s %s %s',
        c_act(@action.to_s),
        @src_spec,
        @log_spec ? @log_spec : ''
     )
    end

    # Search matched ACE
    # @param [Hash] opts Options (target packet info)
    # @option opts [String] :src_ip Source IP Address
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError] Invalid src_ip
    def matches?(opts)
      if opts[:src_ip]
        return @src_spec.ip_spec.matches?(opts[:src_ip])
      else
        fail AclArgumentError, 'Invalid match target src IP address'
      end
    end
  end

  # ACE for extended access list
  class ExtendedAce < StandardAce

    # @param [String] value L3/L4 protocol
    # @return [String]
    attr_accessor :protocol

    # @param [AceSrcDstSpec] value Destination spec object
    # @return [AceSrcDstSpec]
    attr_accessor :dst_spec

    # @param [AceTcpFlagList] value
    #   TCP flags (used when '@protocol':tcp)
    # @return [AceTcpFlagList]
    attr_accessor :tcp_flags

    # @param [AceOtherQualifierList] value
    #   TCP other qualifier list object (used when '@protocol':tcp)
    # @return [AceOtherQualifierList]
    attr_accessor :tcp_other_qualifiers

    #
    # :src, :dst は object class によって処理をかえているので、おなじ引数で
    # AceSrcDstSpec の引数hashをわたしてもよいし、 AceSrcDstSpec Object を
    # わたしてもよい。
    # :protocol も同様(ACEIPProtocolSpec Object)
    #
    # :protocol については name/number の指定がある(parser内部で指示)
    # 基本的には名前だけでよい(名前<=>番号の相互変換をするか? 番号を使うか?)
    #

    # Constructor
    # @param [Hash] opts Options
    # @option opts [String] :protocol L3/L4 protocol
    # @option opts [Integer] :number Protocol/Port number
    # @option opts [String] :action Action
    # @option opts [AceSrcDstSpec] :src Source spec object
    # @option opts [Hash] :src Source spec parmeters
    # @option opts [AceSrcDstSpec] :dst Destination spec object
    # @option opts [Hash] :dst Destination spec parmeters
    # @option opts [AceTcpFlagList] :tcp_port_qualifier
    #   TCP Flags object
    # @raise [AclArgumentError]
    # @return [ExtendACE]
    #
    # @example Construct ACE object
    #   ExtendACE.new(
    #     :protocol => 'tcp',
    #     :number => 10,
    #     :action => 'permit',
    #     :src => { :ipaddr => '192.168.3.0', :wildcard => '0.0.0.127' },
    #     :dst => { :ipaddr => '172.30.0.0', :wildcard => '0.0.7.127',
    #               :operator => 'eq', :port1 => 80 })
    #
    def initialize(opts)
      super

      if opts[:protocol]
        case opts[:protocol]
        when AceIpProtoSpec
          @protocol = opts[:protocol]
        else
          @protocol = AceIpProtoSpec.new(
            name: opts[:protocol],
            number: opts[:protocol_num]
         )
        end
      else
        fail AclArgumentError, 'Not specified IP protocol'
      end

      if opts[:dst]
        case opts[:dst]
        when Hash
          @dst_spec = AceSrcDstSpec.new opts[:dst]
        when AceSrcDstSpec
          @dst_spec = opts[:dst]
        else
          fail AclArgumentError, 'Dst spec: unknown class'
        end
      else
        fail AclArgumentError, 'Not specified dst spec'
      end

      if @protocol.name == 'tcp' && opts[:tcp_flags_qualifier]
        @tcp_flags = opts [:tcp_flags_qualifier]
      else
        @tcp_flags = nil
      end

      @tcp_other_qualifiers = nil
    end

    # @param [ExtendACE] other RHS object
    # @return [Boolean]
    def ==(other)
      @action == other.action &&
        @protocol == other.protocol &&
        @src_spec == other.src_spec &&
        @dst_spec == other.dst_spec &&
        @tcp_flags == other.tcp_flags
      ## does it need to compare? : tcp_other_qualifiers
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      sprintf(
        ' %s %s %s %s %s %s',
        c_act(@action.to_s),
        c_pp(@protocol.to_s),
        @src_spec,
        @dst_spec,
        @tcp_flags ? @tcp_flags : '',
        @tcp_other_qualifiers ? @tcp_other_qualifiers : ''
     )
    end

    # Search matched ACE
    # @param [Hash] opts Options (target packet info)
    # @option opts [String] :protocol L3/L4 protocol name
    #   (allows "tcp", "udp" and "icmp")
    # @option opts [String] :src_ip Source IP Address
    # @option opts [String] :src_port Source Port No.
    # @option opts [String] :dst_ip Destination IP Address
    # @option opts [String] :dst_port Destination Port No.
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError]
    def matches?(opts)
      if opts[:protocol]
        match_proto = true
        if @protocol.to_s != 'ip'
          ## TBD
          ## 名前リテラルなし、プロトコル番号での指定とかどうする?
          ## 原則ぜんぶオブジェクトに変換してから比較をすべき。
          match_proto = (opts[:protocol] == @protocol.to_s)
        end

        match_src = false
        if opts[:src_ip]
          match_src = @src_spec.matches?(opts[:src_ip], opts[:src_port])
        else
          fail AclArgumentError, 'Not specified match target src IP Addr'
        end

        match_dst = false
        if opts[:dst_ip]
          match_dst = @dst_spec.matches?(opts[:dst_ip], opts[:dst_port])
        else
          fail AclArgumentError, 'Not specified match target dst IP Addr'
        end
      else
        fail AclArgumentError, 'Invalid match target protocol'
      end

      (match_proto && match_src && match_dst)
    end

  end

end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
