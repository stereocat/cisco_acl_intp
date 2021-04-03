# frozen_string_literal: true

require 'forwardable'
require 'cisco_acl_intp/ace_extended'
require 'cisco_acl_intp/acl_utils'
require 'cisco_acl_intp/acc'

module CiscoAclIntp
  # ACL (access-list) container.
  # ACL is composed of ACL-Header and ACE-List.
  # ACL has list(set) of ACE and functions to operate ACE list.
  class AclBase < AccessControlContainer
    extend Forwardable
    include Enumerable
    include AceSearchUtility

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
    # @return [AclBase]
    def initialize(name)
      super()
      @name = name # ACL name
      @list = [] # List of ACE
      @seq_number = 0 # Sequence Number of ACE

      @acl_type = nil # :standard or :extended
      @name_type = nil # :named or :numbered
    end

    # duplicate ACE list
    # @param [Array<AceBase>] list List of ACE
    # @return [AclBase]
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
      ace.seq_number = (@list.length + 1) * SEQ_NUM_DIV unless ace.seq_number?
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

    # Check equality
    # @return [Boolean]
    def ==(other)
      @acl_type &&
        @name_type &&
        @acl_type == other.acl_type &&
        @name_type == other.name_type &&
        @list == other.list
    end

    # Find lists of ACEs that contains flow by options
    # @param [Hash] opts Options (target packet info)
    #   options are same as #find_aces_with
    # @see #find_aces_with
    # @return [Array<AceBase>] List of ACEs or nil(not found)
    def find_aces_contains(opts)
      find_aces_with(opts) { |ace, target_ace| ace.contains?(target_ace) }
    end

    # Find lists of ACEs that is contained flow by options
    # @param [Hash] opts Options (target packet info)
    #   options are same as #find_aces_with
    # @see #find_aces_with
    # @return [Array<AceBase>] List of ACEs or nil(not found)
    def find_aces_contained(opts)
      find_aces_with(opts) { |ace, target_ace| target_ace.contains?(ace) }
    end

    # Find lists of ACEs
    # @note In Standard ACL, only src_ip option is used and another
    #   conditions are ignored (if specified).
    # @param [Hash] opts Options (target flow info),
    # @option opts [Integer,String] protocol L3 protocol No./Name
    # @option opts [String] src_ip Source IP Address
    # @option opts [String] src_operator Source port operator.
    # @option opts [Integer,String] src_begin_port Source Port No./Name
    # @option opts [Integer,String] src_end_port Source Port No./Name
    # @option opts [String] dst_ip Destination IP Address
    # @option opts [Integer,String] dst_begin_port Destination Port No./Name
    # @option opts [Integer,String] dst_end_port Destination Port No./Name
    # @yield Find lists of ACEs
    # @yieldparam [ExtendedAce] ace ACE
    # @yieldparam [ExtendedAce] target_ace Target ACE
    # @yieldreturn [Boolean] Condition to find
    # @return [Array<AceBase>] List of ACEs or nil(not found)
    def find_aces_with(opts)
      target_ace = target_ace(opts)
      @list.find { |ace| yield(ace, target_ace) }
    end

    # acl string clean-up (override)
    # @param [String] str ACL string.
    # @return [String]
    def clean_acl_string(str)
      str =~ /remark/ ? str : super
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
