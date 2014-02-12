# -*- coding: utf-8 -*-

require 'forwardable'
require 'cisco_acl_intp/acl_base'

module CiscoAclIntp
  # TCP flag container
  class AceTcpFlag < AclContainerBase
    # @param [String] value TCP flag name
    # @return [String]
    attr_accessor :flag

    # Constructor
    # @param [String] flag TCP flag name
    # @return [AceTcpFlag]
    def initialize(flag)
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
  class AceTcpFlagList < AclContainerBase
    extend Forwardable

    # @param [Array] value TCP Flags
    # @return [Array]
    attr_accessor :list

    def_delegators :@list, :push, :pop, :shift, :unshift, :size, :length

    # Constructor
    # @param [Array<AceTcpFlag>] args TCP Flag Objects
    # @todo If the object that are same are included in the list?
    def initialize(*args)
      @list = args || []
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      tag_port(@list.map { |each| each.to_s }.join(' '))
    end

    # @param [AceTcpFlagList] other RHS Object
    # @note Checked each entry in randum order.
    # @return [Boolean]
    def ==(other)
      @list.reduce(true) do |res, each|
        puts "#{res},#{each}"
        res && other.list.include?(each)
      end
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
