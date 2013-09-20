# -*- coding: utf-8 -*-

require 'forwardable'
require 'CiscoAclIntp/acl-base'

module CiscoAclIntp

  # List of other-qualifiers for extended ace
  class AceOtherQualifierList < AclContainerBase
    extend Forwardable

    # @param [Array] value List of {AceOtherQualifierList} object
    # @return [Array]
    attr_accessor :list

    def_delegators :@list, :push, :pop, :shift, :unshift, :size, :length

    # Constructor
    # @return [AceOtherQualifierList]
    def initialize
      @list = []
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      c_pp( @list.map { | each | each.to_s }.join(' ') )
    end

    # @param [AceOtherQualifierList] other RHS Object
    # @return [Boolean]
    def == other
      @list == other.list
    end
  end

  # Access list entry qualifier base
  class AceOtherQualifierBase < AclContainerBase
  end

  # Log spec container
  class AceLogSpec < AceOtherQualifierBase

    # @param [String] value Log cookie
    # @return [String]
    attr_accessor :cookie

    # Specified log-input logging?
    # @return [Boolean]
    def input?
      @input
    end

    # Constructor
    # @param [String] cookie Log cookie
    # @param [Boolean] input set true 'log-input' logging
    # @return [AceLogSpec]
    def initialize cookie = nil, input = false
      @input = input
      @cookie = cookie
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      sprintf( "%s %s",
        @input ? "log-input" : "log",
        @cookie ? @cookie : ""
      )
    end
  end

  # Recursive qualifier container
  class AceRecursiveQualifier < AceOtherQualifierBase

    # @param [String] value Recursive name
    # @return [String]
    attr_accessor :recursive_name

    # Constructor
    # @param [String] name Recursive name
    def initialize name
      if name and ( not name.empty? )
        @recursive_name = name
      else
        raise AclArgumentError, "Not specified recursive name"
      end
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      sprintf "reflect %s", c_name( @recursive_name )
    end
  end

end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
