# -*- coding: utf-8 -*-

require 'forwardable'
require 'cisco_acl_intp/ace'

module CiscoAclIntp

  # Single access-list container base
  class SingleAclBase < AclContainerBase
    extend Forwardable

    # @return [String] name ACL name,
    #   when numbered acl, /\d+/ string
    attr_reader :name 
    # @return [Array] list ACE object Array
    attr_reader :list
    # @return [String, Symbol] acl_type ACL type
    attr_reader :acl_type
    # @return [String, Symbol] name_type ACL name type
    attr_reader :name_type

    def_delegators :@list, :pop, :unshift, :size, :length

    # Increment number of ACL sequence number
    SEQ_NUM_DIV = 10

    # Constructor
    # @param [String] name ACL name
    # @return [SingleAclBase]
    def initialize name
      @name = name
      @list = []
      @seq_number = 0

      @acl_type = nil # :standard or :extended
      @name_type = nil # :named or :numbered
    end

    # Add ACE to ACL
    # @param [AceBase] ace ACE object
    def add_entry ace
      # 'ace' is AceBase Object
      # it will be ExtendedAce/StandardAce/RemarkAce/EvaluateAce
      if not ace.has_seq_number?
        ace.seq_number = ( @list.length + 1 ) * SEQ_NUM_DIV
      end
      @list.push ace
    end

    # Sort ACL by sequence number
    def sort
      ## TBD, sort by seq_number
    end

    # Renumber ACL by list sequence
    def renumber
      ## TBD, re-numbering seq_number of each entry
    end

    # @return [Boolean]
    def == other
      if @acl_type and
          @name_type and
          @acl_type == other.acl_type and
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
    def search_ace opts
      ## TBD ##
      @list.each do | each |
        return each if each.matches?( opts )
      end
      nil
    end

  end

  ############################################################

  # Features for Extended ACL
  module ExtAcl
    ## TBD
    ## add_entry で StandardAce がきたらはじく、とかやるか?

    # Generate a Extended ACE by parameters
    #   and Add it to ACL
    # @param [Hash] opts Options to create {ExtendedAce}
    def add_entry_by_params opts
      ace = ExtendedAce.new opts
      add_entry ace
    end
  end

  # Features for Standard ACL
  module StdAcl
    ## TBD
    ## add_entry で ExtendedAce がきたらはじく、とかやるか?

    # Generate a Standard ACE by parameters
    #   and Add it to ACL
    # @param [Hash] opts Options to create {StandardAce}
    def add_entry_by_params opts
      ace = StandardAce.new opts
      add_entry ace
    end
  end

  ############################################################

  # Named ACL container base
  class NamedAcl < SingleAclBase

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      strings = [
        sprintf(
          "%s %s %s",
          c_hdr( "ip access-list" ),
          c_type( @acl_type ),
          c_name( @name )
        )
      ]
      @list.each { | entry | strings.push entry.to_s }
      strings.join("\n")
    end
  end

  # Numbered ACL container base
  class NumberedAcl < SingleAclBase

    # @return [Integer] Access list number
    attr_reader :number

    # Constructor
    # @param [String, Integer] name ACL number
    # @raise [AclArgumentError]
    # @return [NumberedAcl]
    def initialize name
      super

      ## TBD
      ## name の代入演算子もどうにかする必要があるはず。(attr_accessor)

      case name
      when Fixnum
        @name = name.to_s
        @number = name
      when String
        if name =~ /\A\d+\Z/
          @name = name
          @number = name.to_i
        else
          raise AclArgumentError, "acl number string is not integer"
        end
      else
        raise AclArgumentError, "acl number error"
      end
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      strings = []
      @list.each do | entry |
        strings.push sprintf(
          "%s %s %s",
          c_hdr( "access-list" ),
          c_name( @name ),
          entry
        )
      end
      strings.join("\n")
    end
  end

  ############################################################

  # Named extended ACL container
  class NamedExtAcl < NamedAcl
    include ExtAcl

    # Constructor
    # @param [String] name ACL name
    # @return [NamedExtAcl]
    def initialize name
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
    def initialize name
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
    def initialize name
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
    def initialize name
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
