# -*- coding: utf-8 -*-

require 'cisco_acl_intp/ace-srcdst'

module CiscoAclIntp

  # Access control entry base model
  class AceBase < AclContainerBase
    include Comparable

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
    def seq_number?
      @seq_number > NO_SEQ_NUMBER
    end

    # Compare by sequence number
    #   Note: Using Comparable module, '==' operator defined by '<=>'.
    #   But ACE object will be compared by its value (comparison by
    #   the equivalence), instead of sequence number. The '=='
    #   operator will be overriden in child class.
    # @param [AceBase] other RHS object
    # @return [Integer] Compare with protocol/port number
    def <=>(other)
      @seq_number <=> other.seq_number
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

      set_action(opts)
      if opts[:src]
        set_src_spec(opts)
      else
        fail AclArgumentError, 'Not specified src spec'
      end
      set_log_spec(opts)
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

    private

    # Set instance variables
    # @param [Hash] opts Options of constructor
    # @raise [AclArgumentError]
    def set_action(opts)
      if opts[:action]
        @action = opts[:action]
      else
        fail AclArgumentError, 'Not specified action'
      end
    end

    # Set instance variables
    # @param [Hash] opts Options of constructor
    # @raise [AclArgumentError]
    def set_src_spec(opts)
      case opts[:src]
      when Hash
        @src_spec = AceSrcDstSpec.new opts[:src]
      when AceSrcDstSpec
        @src_spec = opts[:src]
      else
        fail AclArgumentError, 'src spec: unknown class'
      end
    end

    # Set instance variables
    # @param [Hash] opts Options of constructor
    # @raise [AclArgumentError]
    def set_log_spec(opts)
      @log_spec = opts[:log] || nil
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

    # Option,
    # :src and :dst can handle multiple types of object generation,
    # so that the argments can takes hash of AceSrcDstSpec.new or
    # AceSrcDstSpec instance.
    # :protocol and so on. (AceIpProtoSpec Object)
    #
    # about :protocol, it has specification of name and number
    # (specified in internal of parser).
    # basically, it is OK that specify only name.
    # (does it convert name <=> number each oether?)
    # (does it use number?
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
      validate_protocol(opts)
      validate_dst_spec(opts)
      set_tcp_info(opts)
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
    # @option opts [Integer] :src_port Source Port No.
    # @option opts [String] :dst_ip Destination IP Address
    # @option opts [Integer] :dst_port Destination Port No.
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError]
    def matches?(opts)
      if opts[:protocol]
        match_proto = match_protocol?(opts[:protocol])
        match_src = match_addr_port?(@src_spec, opts[:src_ip], opts[:src_port])
        match_dst = match_addr_port?(@dst_spec, opts[:dst_ip], opts[:dst_port])
      else
        fail AclArgumentError, 'Invalid match target protocol'
      end

      (match_proto && match_src && match_dst)
    end

    private

    # check protocol
    # @option protocol [AceProtoSpecBase] protocol
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError]
    def match_protocol?(protocol)
      if @protocol.to_s == 'ip'
        is_match = true # allow tcp/udp
      else
        ## TBD
        ## what to do when NO name and only protocol number is specified?
        # In principle, it must be compared by object.
        is_match = (protocol == @protocol.to_s)
      end
      is_match
    end

    # check src/dst address
    # @option srcdst_spec [AceSrcDstSpec] src/dst address/port
    # @option ip [String] ip addr to compare
    # @option port [Integer] port number to compare
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError]
    def match_addr_port?(srcdst_spec, ip, port)
      is_match = false
      if ip
        is_match = srcdst_spec.matches?(ip, port)
      else
        fail AclArgumentError, 'Not specified match target IP Addr'
      end
      is_match
    end

    # Validate options
    # @param [Hash] opts Options of constructor
    def validate_protocol(opts)
      if opts[:protocol]
        set_protocol(opts)
      else
        fail AclArgumentError, 'Not specified IP protocol'
      end
    end

    # Validate options
    # @param [Hash] opts Options of constructor
    def validate_dst_spec(opts)
      if opts[:dst]
        set_dst_spec(opts)
      else
        fail AclArgumentError, 'Not specified dst spec'
      end
    end

    # Set instance variables
    # @param [Hash] opts Options of constructor
    def set_protocol(opts)
      case opts[:protocol]
      when AceIpProtoSpec
        @protocol = opts[:protocol]
      else
        @protocol = AceIpProtoSpec.new(
          name: opts[:protocol],
          number: opts[:protocol_num]
        )
      end
    end

    # Set instance variables
    # @param [Hash] opts Options of constructor
    def set_dst_spec(opts)
      case opts[:dst]
      when Hash
        @dst_spec = AceSrcDstSpec.new opts[:dst]
      when AceSrcDstSpec
        @dst_spec = opts[:dst]
      else
        fail AclArgumentError, 'Dst spec: unknown class'
      end
    end

    # Set instance variables
    # @param [Hash] opts Options of constructor
    def set_tcp_info(opts)
      if @protocol.name == 'tcp' && opts[:tcp_flags_qualifier]
        @tcp_flags = opts [:tcp_flags_qualifier]
      else
        @tcp_flags = nil
      end
      @tcp_other_qualifiers = nil
    end

  end

end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
