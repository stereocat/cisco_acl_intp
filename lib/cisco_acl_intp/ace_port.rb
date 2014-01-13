# -*- coding: utf-8 -*-

require 'forwardable'
require 'cisco_acl_intp/ace_proto'

module CiscoAclIntp
  # TCP/UDP port number and operator container
  class AcePortSpec < AclContainerBase
    include AceTcpUdpPortValidation

    # @param [String] value Operator of port (eq/neq/gt/lt/range)
    # @return [String]
    attr_accessor :operator

    # @param [AceProtoSpecBase] value Port No. (single/lower)
    # @return [AceProtoSpecBase]
    attr_accessor :port1

    # @param [AceProtoSpecBase] value Port No. (higher)
    # @return [AceProtoSpecBase]
    attr_accessor :port2

    # Constructor
    # @param [Hash] opts Options
    # @option opts [String] :operator Port operator, eq/neq/lt/gt/range
    # @option opts [AceProtoSpecBase] :port1 Port No. (single/lower)
    # @option opts [AceProtoSpecBase] :port2 Port No. (higher)
    # @raise [AclArgumentError]
    # @return [AcePortSpec]
    # @note '@port1' and '@port2' should managed
    #   with port number and protocol name.
    #   it need the number when operate/compare protocol number,
    #   and need the name when stringize the object.
    def initialize(opts)
      ## TBD
      ## in ACL, can "eq/neq" receive port list?
      ## IOS15 later?

      if opts[:operator]
        define_operators(opts)
        validate_operators(opts)
      else
        fail AclArgumentError, 'Not specified port operator'
      end
    end

    # @param [AcePortSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @operator == other.operator &&
        @port1 == other.port1 &&
        @port2 == other.port2
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      if @operator == 'any'
        ''
      else
        c_pp(sprintf(
            '%s %s %s',
            @operator ? @operator : '',
            @port1 ? @port1 : '',
            @port2 ? @port2 : ''
        ))
      end
    end

    # Table of port match operator and operations
    PORT_OPERATE = {
      'any'   => proc { |p1, p2, p| true },
      'eq'    => proc { |p1, p2, p| p1 == p },
      'neq'   => proc { |p1, p2, p| p1 != p },
      'gt'    => proc { |p1, p2, p| p1  < p },
      'lt'    => proc { |p1, p2, p| p1  > p },
      'range' => proc { |p1, p2, p| (p1 .. p2).include?(p) },
    }

    # Check the port number matches this?
    # @param [Integer] port TCP/UDP Port number
    # @raise [AclArgumentError]
    # @return [Boolean]
    def matches?(port)
      unless valid_range?(port)
        fail AclArgumentError, "Port out of range: #{ port }"
      end
      # @operator was validated in constructor
      PORT_OPERATE[@operator].call(@port1.to_i, @port2.to_i, port)
    end

    private

    # Set instance variables
    # @param [Hash] opts Options of constructor
    def define_operators(opts)
      @operator = opts[:operator]
      @port1 = opts[:port1] || nil
      @port2 = opts[:port2] || nil
    end

    # Varidate options
    # @param [Hash] opts Options of constructor
    # @raise [AclArgumentError]
    def validate_operators(opts)
      if (!@port1) && (@operator != 'any')
        fail AclArgumentError, 'Not specified port_1'
      elsif opts[:port2] && (opts[:port1] > opts[:port2])
        fail(
          AclArgumentError,
          'Not specified port_2 or Invalid port range args sequence'
        )
      elsif !PORT_OPERATE[@operator]
        fail AclArgumentError, "Unknown operator: #{@operator}"
      end
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
