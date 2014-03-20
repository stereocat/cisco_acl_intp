# -*- coding: utf-8 -*-

require 'forwardable'
require 'cisco_acl_intp/extended_ace'

module CiscoAclIntp
  # Single access-list container base
  class SingleAclBase < AclContainerBase
    extend Forwardable
    include Enumerable

    # @return [String] name ACL name,
    #   when numbered acl, /\d+/ string
    attr_reader :name
    # Some Enumerable included methods returns Array of ACE objects
    # (e.g. sort),the returned Array was used as ACE object by
    # overwrite accessor 'list'.
    # @return [Array<AceBase>] list ACE object Array
    attr_accessor :list
    # @return [String, Symbol] acl_type ACL type
    attr_reader :acl_type
    # @return [String, Symbol] name_type ACL name type
    attr_reader :name_type

    def_delegators :@list, :each # for Enumerable
    def_delegators :@list, :push, :pop, :shift, :unshift
    def_delegators :@list, :size, :length

    # Increment number of ACL sequence number
    SEQ_NUM_DIV = 10

    # Constructor
    # @param [String] name ACL name
    # @return [SingleAclBase]
    def initialize(name)
      @name = name
      @list = []
      @seq_number = 0

      @acl_type = nil # :standard or :extended
      @name_type = nil # :named or :numbered
    end

    # duplicate ACE list
    # @param [Array<AceBase>] list List of ACE
    # @return [SingleAclBase]
    def dup_with_list(list)
      acl = dup
      acl.list = list.dup
      acl
    end

    # Add ACE to ACL (push with sequence number)
    # @param [AceBase] ace ACE object
    def add_entry(ace)
      # 'ace' is AceBase Object
      # it will be ExtendedAce/StandardAce/RemarkAce/EvaluateAce
      ace.seq_number? ||
        ace.seq_number = (@list.length + 1) * SEQ_NUM_DIV
      @list.push ace
    end

    # Renumber ACL by list sequence
    def renumber
      # re-numbering seq_number of each entry
      @list.reduce(SEQ_NUM_DIV) do |number, each|
        each.seq_number = number
        number + SEQ_NUM_DIV
      end
    end

    # @return [Boolean]
    def ==(other)
      if @acl_type &&
          @name_type &&
          @acl_type == other.acl_type &&
          @name_type == other.name_type
        @list == other.list
      end
    end

    # Search matched ACE from list
    # @note In Standard ACL, only src_ip option is used and another
    #   conditions are ignored (if specified).
    # @param [Hash] opts Options (target packet info),
    # @option opts [Integer,String] protocol L3 protocol No./Name
    # @option opts [String] src_ip Source IP Address
    # @option opts [String] src_operator Source port operator.
    # @option opts [Integer,String] src_begin_port Source Port No./Name
    # @option opts [Integer,String] src_end_port Source Port No./Name
    # @option opts [String] dst_ip Destination IP Address
    # @option opts [Integer,String] dst_begin_port Destination Port No./Name
    # @option opts [Integer,String] dst_end_port Destination Port No./Name
    # @return [AceBase] Matched ACE object or nil(not found)
    # @see StandardAce#contains?
    # @see ExtendedAce#contains?
    # @raise [AclArgumentError]
    def search_ace(opts)
      @list.find { |each| each.contains?(opts) }
    end

    # acl string clean-up (override)
    # @param [String] str ACL string.
    # @return [String]
    def clean_acl_string(str)
      str =~ /remark/ ? str : super
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
