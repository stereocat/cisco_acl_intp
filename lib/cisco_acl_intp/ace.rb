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
    def contains?
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
      other.instance_of?(RemarkAce) && @comment == other.comment
    end

    # Generate string for Cisco IOS access list
    # @return [String] Comment string
    def to_s
      sprintf 'remark %s', tag_remark(@comment.to_s)
    end

    # Search matched ACE
    # @param [Hash] opts Options
    # return [Boolean] false, Remark does not match anithyng.
    def contains?(opts = nil)
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
      other.instance_of?(EvaluateAce) &&
        @recursive_name == other.recursive_name
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      sprintf 'evaluate %s', tag_name(@recursive_name)
    end

    # Search matched ACE
    # @param [Hash] opts Options
    # return [Boolean]
    # @todo for Recursive name matching is not implemented yet
    def contains?(opts = nil)
      false
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
