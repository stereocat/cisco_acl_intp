# -*- coding: utf-8 -*-

require 'cisco_acl_intp/ace_srcdst'

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
      @seq_number = opts[:number] || NO_SEQ_NUMBER
    end

    # Check this object has sequence number
    # @return [Boolean]
    def seq_number?
      @seq_number > NO_SEQ_NUMBER
    end

    # Compare by sequence number
    # @note Using "Comparable" module, '==' operator is defined by
    #   '<=>' operator.  But ACE object will be compared by its value
    #   (comparison by the equivalence), instead of sequence
    #   number. The '==' operator will be overriden in child class.
    # @param [AceBase] other RHS object
    # @return [Integer] Compare with protocol/port number
    def <=>(other)
      @seq_number <=> other.seq_number
    end

    # Search matched ACE
    # @return [Boolean] Matched or not
    # @abstract
    def matches?
      false
    end
  end

  # Error entry container
  class ErrorAce < AceBase
    attr_accessor :line

    def initialize(line)
      super({})
      @line = line
    end

    def to_s
      tag_error(sprintf('!! error !! %s', @line))
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

    # Check equality
    # @return [Boolean] Compare with comment string
    def ==(other)
      @comment == other.comment
    end

    # Generate string for Cisco IOS access list
    # @return [String] Comment string
    def to_s
      sprintf 'remark %s', tag_remark(@comment.to_s)
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
    # @return [EvaluateAce]
    # @raise [AclArgumentError]
    def initialize(opts)
      super
      @options = opts
      @recursive_name = define_recursive_name
    end

    # Set instance variables
    # return [String] Recursive entry name
    # raise [AclArgumentError]
    def define_recursive_name
      if @options.key?(:recursive_name)
        @options[:recursive_name]
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
      sprintf 'evaluate %s', tag_name(@recursive_name)
    end

    # Search matched ACE
    # @param [Hash] opts Options
    # return [Boolean] false, Recursive does not implemented yet
    def matches?(opts = nil)
      ## TODO
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
    # @return [StandardAce]
    # @raise [AclArgumentError]
    def initialize(opts)
      super
      @options = opts
      @action = define_action
      @src_spec = define_src_spec
      @log_spec = define_log_spec
    end

    # @return [Boolean]
    def ==(other)
      @action == other.action && @src_spec == other.src_spec
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      sprintf(
        '%s %s %s',
        tag_action(@action.to_s),
        @src_spec,
        tag_other_qualifier(@log_spec ? @log_spec : '')
     )
    end

    # Search matched ACE
    # @param [Hash] opts Options (target packet info)
    # @option opts [String] :src_ip Source IP Address
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError] Invalid src_ip
    def matches?(opts)
      if opts.key?(:src_ip)
        @src_spec.matches?(opts[:src_ip])
      else
        fail AclArgumentError, 'Invalid match target src IP address'
      end
    end

    private

    # Set instance variables
    # @return [String] Action string
    # @raise [AclArgumentError]
    def define_action
      if @options.key?(:action)
        @options[:action]
      else
        fail AclArgumentError, 'Not specified action'
      end
    end

    # Set instance variables
    # @return [AceSrcDstSpec] Source spec object
    # @raise [AclArgumentError]
    def define_src_spec
      if @options.key?(:src)
        src = @options[:src]
        case src
        when Hash
          AceSrcDstSpec.new(src)
        when AceSrcDstSpec
          src
        else
          fail AclArgumentError, 'src spec: unknown class'
        end
      else
        fail AclArgumentError, 'Not specified src spec'
      end
    end

    # Set instance variables
    # @return [String] Log spec object
    # @raise [AclArgumentError]
    def define_log_spec
      @options[:log] || nil
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
    #               :operator => 'eq', :begin_port => 80 })
    #
    def initialize(opts)
      super
      @options = opts
      @protocol = define_protocol
      @dst_spec = define_dst_spec
      @tcp_flags = define_tcp_flags
      @tcp_other_qualifiers = nil # not yet.
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
        '%s %s %s %s %s %s',
        tag_action(@action.to_s),
        tag_protocol(@protocol.to_s),
        @src_spec,
        @dst_spec,
        @tcp_flags,
        @tcp_other_qualifiers
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
      if opts.key?(:protocol)
        match_protocol?(opts[:protocol]) &&
          @src_spec.matches?(opts[:src_ip], opts[:src_port]) &&
          @dst_spec.matches?(opts[:dst_ip], opts[:dst_port])
      else
        fail AclArgumentError, 'Invalid match target protocol'
      end
    end

    private

    # check protocol
    # @option protocol [AceProtoSpecBase] protocol
    # @return [Boolean] Matched or not
    # @raise [AclArgumentError]
    def match_protocol?(protocol)
      protocol_str = @protocol.to_s
      if protocol_str == 'ip'
        true # allow any of icmp/tcp/udp
      else
        ## TBD
        ## what to do when NO name and only protocol number is specified?
        # In principle, it must be compared by object.
        protocol == protocol_str
      end
    end

    # Set instance variables
    # return [AceIpProtoSpec] IP protocol object
    # raise [AclArgumentError]
    def define_protocol
      if @options.key?(:protocol)
        protocol = @options[:protocol]
        case protocol
        when AceIpProtoSpec
          protocol
        else
          AceIpProtoSpec.new(
            name: protocol,
            number: @options[:protocol_num]
          )
        end
      else
        fail AclArgumentError, 'Not specified IP protocol'
      end
    end

    # Set instance variables
    # @return [AceSrcDstSpec] Destination spec object
    # @raise [AclArgumentError]
    def define_dst_spec
      if @options.key?(:dst)
        dst = @options[:dst]
        case dst
        when Hash
          AceSrcDstSpec.new(dst)
        when AceSrcDstSpec
          dst
        else
          fail AclArgumentError, 'Dst spec: unknown class'
        end
      else
        fail AclArgumentError, 'Not specified dst spec'
      end
    end

    # Set instance variables
    # @return [AceOtherQualifierList]
    def define_tcp_flags
      if @protocol.name == 'tcp' && @options.key?(:tcp_flags_qualifier)
        @options[:tcp_flags_qualifier]
      else
        nil
      end
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
