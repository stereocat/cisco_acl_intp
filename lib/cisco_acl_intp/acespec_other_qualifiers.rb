# frozen_string_literal: true

require 'forwardable'
require 'cisco_acl_intp/acespec_base'

module CiscoAclIntp
  # List of other-qualifiers for extended ace
  class AceOtherQualifierList < AceSpecBase
    extend Forwardable

    # @param [Array] value List of {AceOtherQualifierList} object
    # @return [Array]
    attr_accessor :list

    def_delegators :@list, :push, :pop, :shift, :unshift, :size, :length

    # Constructor
    # @return [AceOtherQualifierList]
    def initialize(list = [])
      super()
      @list = list
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      tag_other_qualifier(@list.map(&:to_s).join(' '))
    end

    # @param [AceOtherQualifierList] other RHS Object
    # @return [Boolean]
    def ==(other)
      @list.reduce(true) do |res, each|
        res && other.list.include?(each)
      end
    end
  end

  # Access list entry qualifier base
  class AceOtherQualifierBase < AceSpecBase
  end

  # Log spec container
  class AceLogSpec < AceOtherQualifierBase
    # @param [String] value Log cookie
    # @return [String]
    attr_accessor :cookie

    # Specified log-input logging?
    # @return [Boolean]
    attr_accessor :input

    # alias as boolean method
    # @return [Boolean]
    alias input? input

    # Constructor
    # @param [String] cookie Log cookie
    # @param [Boolean] input set true 'log-input' logging
    # @return [AceLogSpec]
    def initialize(cookie = nil, input = nil)
      super()
      @input = !input.nil? # default nil = false
      @cookie = cookie
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      format(
        '%<input>s %<cookie>s',
        input: @input ? 'log-input' : 'log',
        cookie: @cookie || ''
      )
    end

    # @param [AceLogSpec] other RHS object
    # @return [Boolean]
    def ==(other)
      other.instance_of?(AceLogSpec) &&
        @input == other.input &&
        @cookie == other.cookie
    end
  end

  # Recursive qualifier container
  class AceRecursiveQualifier < AceOtherQualifierBase
    # @param [String] value Recursive name
    # @return [String]
    attr_accessor :recursive_name

    # Constructor
    # @param [String] name Recursive name
    def initialize(name)
      super()
      raise AclArgumentError, 'Not specified recursive name' unless name && !name.empty?

      @recursive_name = name
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      format 'reflect %s', tag_name(@recursive_name)
    end

    # @param [AceRecursiveQualifier] other RHS object
    # @return [Boolean]
    def ==(other)
      other.instance_of?(AceRecursiveQualifier) &&
        @recursive_name == other.recursive_name
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
