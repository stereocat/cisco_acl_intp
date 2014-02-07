# -*- coding: utf-8 -*-

require 'forwardable'
require 'cisco_acl_intp/ace'

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
    # @return [Array <AceBase>] list ACE object Array
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

    # duplicate with list
    # @param [Array<SingleAclBase>]
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
    # @param [Hash] opts Options (target packet info)
    # @option [String, Symbol] protocol L3/L4 protocol name
    #   (allows :tcp, :udp and :icmp)
    # @option [String] src_ip Source IP Address
    # @option [String] src_port Source Port
    # @option [String] dst_ip Destination IP Address
    # @option [String] dst_port Destination Port
    # @return [AceBase] Matched ACE object or nil(not found)
    # @raise [AclArgumentError]
    def search_ace(opts)
      @list.find { |each| each.matches?(opts) }
    end

    # acl string clean-up (override)
    # @param [String] str ACL string.
    # @return [String]
    def clean_acl_string(str)
      str =~ /remark/ ? str : super
    end
  end

  ############################################################

  # Features for Extended ACL
  module ExtAcl
    ## TBD
    ## does it have to raise error
    ## if add_entry called with StandardAce?

    # Generate a Extended ACE by parameters
    #   and Add it to ACL
    # @param [Hash] opts Options to create {ExtendedAce}
    def add_entry_by_params(opts)
      ace = ExtendedAce.new opts
      add_entry ace
    end
  end

  # Features for Standard ACL
  module StdAcl
    ## TBD
    ## does it have to raise error
    ## if add_entry called with ExtendedAce?

    # Generate a Standard ACE by parameters
    #   and Add it to ACL
    # @param [Hash] opts Options to create {StandardAce}
    def add_entry_by_params(opts)
      ace = StandardAce.new opts
      add_entry ace
    end
  end

  ############################################################

  # Named ACL container base
  class NamedAcl < SingleAclBase
    # check acl type,Named ACL or not?
    # @return [Boolean]
    def named_acl?
      true
    end

    # check acl type, Numbered ACL or not?
    # @return [Boolean]
    def numbered_acl?
      false
    end

    # Generate ACL header string
    # @return [String] ACL header string
    def header_string
      sprintf(
        '%s %s %s',
        tag_header('ip access-list'),
        tag_type(@acl_type),
        tag_name(@name)
      )
    end

    # Generate ACL line string
    # @param [AceBase] entry ACE object
    def line_string(entry)
      # add indent
      sprintf(' %s', clean_acl_string(entry.to_s))
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      strings = @list.each_with_object([header_string]) do |entry, strlist|
        strlist.push line_string(entry)
      end
      strings.join("\n")
    end
  end

  # Numbered ACL container base
  class NumberedAcl < SingleAclBase
    # @return [Integer] Access list number
    attr_reader :number

    # check acl type,Named ACL or not?
    # @return [Boolean]
    def named_acl?
      false
    end

    # check acl type, Numbered ACL or not?
    # @return [Boolean]
    def numbered_acl?
      true
    end

    # Constructor
    # @param [String, Integer] name ACL number
    # @raise [AclArgumentError]
    # @return [NumberedAcl]
    def initialize(name)
      super

      ## TBD
      ## it ought to do something about assignment operator...
      ## (attr_reader)

      case name
      when Fixnum
        set_name_and_number(name.to_s, name)
      when String
        validate_name_by_string(name)
      else
        fail AclArgumentError, 'acl number error'
      end
    end

    # Generate ACL header string
    # @return [String] ACL header string
    def header_string
      sprintf(
        '%s %s',
        tag_header('access-list'),
        tag_name(@name)
      )
    end

    # Generate ACL line string
    # @param [AceBase] entry ACE object
    def line_string(entry)
      clean_acl_string(sprintf('%s %s', header_string, entry))
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      strings = @list.each_with_object([]) do |entry, strlist|
        strlist.push line_string(entry)
      end
      strings.join("\n")
    end

    private

    # validate instance variables
    # @param [String] name ACL Name
    def validate_name_by_string(name)
      if name =~ /\A\d+\Z/
        set_name_and_number(name, name.to_i)
      else
        fail AclArgumentError, 'acl number string is not integer'
      end
    end

    # Set instance variables
    def set_name_and_number(name, number)
      @name = name
      @number = number
    end
  end

  ############################################################

  # Named extended ACL container
  class NamedExtAcl < NamedAcl
    include ExtAcl

    # Constructor
    # @param [String] name ACL name
    # @return [NamedExtAcl]
    def initialize(name)
      super
      @name_type = :named
      @acl_type = :extended
    end
  end

  # Numbered extended ACL container
  class NumberedExtAcl < NumberedAcl
    include ExtAcl

    # Constructor
    # @param [String, Integer] name ACL name
    # @return [NumberedExtAcl]
    def initialize(name)
      super
      @name_type = :numbered
      @acl_type = :extended
    end
  end

  # Named standard ACL container
  class NamedStdAcl < NamedAcl
    include StdAcl

    # Constructor
    # @param [String] name ACL name
    # @return [NamedStdAcl]
    def initialize(name)
      super
      @name_type = :named
      @acl_type = :standard
    end
  end

  # Numbered standard ACL container
  class NumberedStdAcl < NumberedAcl
    include StdAcl

    # Constructor
    # @param [String, Integer] name ACL name
    # @return [NumberedStdAcl]
    def initialize(name)
      super
      @name_type = :numbered
      @acl_type = :standard
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
