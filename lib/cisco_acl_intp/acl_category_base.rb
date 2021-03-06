# frozen_string_literal: true

require 'forwardable'
require 'cisco_acl_intp/acl_base'

module CiscoAclIntp
  # Features for Extended ACL
  # @todo Does it have to raise error if add_entry called with
  #   StandardAce?
  module ExtAcl
    # Generate a Extended ACE by parameters
    #   and Add it to ACL
    # @param [Hash] opts Options to create {ExtendedAce}
    def add_entry_by_params(opts)
      ace = ExtendedAce.new opts
      add_entry ace
    end
  end

  # Features for Standard ACL
  # @todo Does it have to raise error if add_entry called with
  #   ExtendedAce?
  module StdAcl
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
  class NamedAcl < AclBase
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
      format(
        '%<hdr>s %<type>s %<name>s',
        hdr: tag_header('ip access-list'),
        type: tag_type(@acl_type),
        name: tag_name(@name)
      )
    end

    # Generate ACL line string
    # @param [AceBase] entry ACE object
    def line_string(entry)
      # add indent
      format ' %<str>s', str: clean_acl_string(entry.to_s)
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
  class NumberedAcl < AclBase
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
    # @todo It ought to do something about assignment operator...
    #   (attr_reader)
    def initialize(name)
      super
      case name
      when Integer
        set_name_and_number(name.to_s, name)
      when String
        validate_name_by_string(name)
      else
        raise AclArgumentError, 'acl number error'
      end
    end

    # Generate ACL header string
    # @return [String] ACL header string
    def header_string
      format(
        '%<hdr>s %<name>s',
        hdr: tag_header('access-list'),
        name: tag_name(@name)
      )
    end

    # Generate ACL line string
    # @param [AceBase] entry ACE object
    def line_string(entry)
      clean_acl_string(format('%<hdr>s %<entry>s', hdr: header_string, entry: entry))
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
      raise AclArgumentError, 'acl number string is not integer' unless name =~ /\A\d+\Z/

      set_name_and_number(name, name.to_i)
    end

    # Set instance variables
    def set_name_and_number(name, number)
      @name = name
      @number = number
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
