# frozen_string_literal: true

require 'forwardable'
require 'cisco_acl_intp/acespec_base'

module CiscoAclIntp
  # TCP flag container
  class AceTcpFlag < AceSpecBase
    # @param [String] value TCP flag name
    # @return [String]
    attr_accessor :flag

    # Constructor
    # @param [String] flag TCP flag name
    # @return [AceTcpFlag]
    def initialize(flag)
      super()
      @flag = flag
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      @flag.to_s
    end

    # @param [AceTcpFlag] other RHS Object
    # @return [Boolean]
    def ==(other)
      @flag == other.flag
    end
  end

  # TCP flag list container
  class AceTcpFlagList < AceSpecBase
    extend Forwardable

    # @param [Array] value TCP Flags
    # @return [Array]
    attr_accessor :list

    def_delegators :@list, :push, :pop, :shift, :unshift, :size, :length

    # Constructor
    # @param [Array<AceTcpFlag>] list TCP Flag Objects
    # @todo If the object that are same are included in the list?
    def initialize(list = [])
      super()
      @list = list
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      tag_port(@list.map(&:to_s).join(' '))
    end

    # @param [AceTcpFlagList] other RHS Object
    # @note Checked each entry in randum order.
    # @return [Boolean]
    def ==(other)
      @list.reduce(true) do |res, each|
        res && other.list.include?(each)
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
