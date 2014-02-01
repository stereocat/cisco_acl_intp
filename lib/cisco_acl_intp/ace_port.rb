# -*- coding: utf-8 -*-

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
    attr_accessor :begin_port

    # alias for unary operator
    alias_method :port, :begin_port

    # @param [AceProtoSpecBase] value Port No. (higher)
    # @return [AceProtoSpecBase]
    attr_accessor :end_port

    # Constructor
    # @param [Hash] opts Options
    # @option opts [String] :operator Port operator, eq/neq/lt/gt/range
    # @option opts [AceProtoSpecBase] :port Port No. (single/lower)
    #   (same as :begin_port, alias for unary operator)
    # @option opts [AceProtoSpecBase] :begin_port Port No. (single/lower)
    # @option opts [AceProtoSpecBase] :end_port Port No. (higher)
    # @raise [AclArgumentError]
    # @return [AcePortSpec]
    # @note '@begin_port' and '@end_port' should managed
    #   with port number and protocol name.
    #   it need the number when operate/compare protocol number,
    #   and need the name when stringize the object.
    def initialize(opts)
      ## TBD
      ## in ACL, can "eq/neq" receive port list?
      ## IOS15 later?

      if opts.key?(:operator)
        validate_operators(opts)
      else
        fail AclArgumentError, 'Not specified port operator'
      end
    end

    # @param [AcePortSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @operator == other.operator &&
        @begin_port == other.begin_port &&
        @end_port == other.end_port
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      if @operator == 'any'
        ''
      else
        tag_port(sprintf('%s %s %s', @operator, @begin_port, @end_port))
      end
    end

    # Table of port match operator and operations
    PORT_OPERATE = {
      'any'   => proc do |begin_port, end_port, port|
        true
      end,
      'eq'    => proc do |begin_port, end_port, port|
        begin_port == port
      end,
      'neq'   => proc do |begin_port, end_port, port|
        begin_port != port
      end,
      'gt'    => proc do |begin_port, end_port, port|
        begin_port  < port
      end,
      'lt'    => proc do |begin_port, end_port, port|
        begin_port  > port
      end,
      'range' => proc do |begin_port, end_port, port|
        (begin_port .. end_port).include?(port)
      end,
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
      PORT_OPERATE[@operator].call(@begin_port.to_i, @end_port.to_i, port)
    end

    private

    # Set instance variables
    # @param [Hash] opts Options of constructor
    def define_operator_and_ports(opts)
      @operator = opts[:operator] || 'any'
      @begin_port = opts[:port] || opts[:begin_port] || nil
      @end_port = opts[:end_port] || nil
    end

    # Varidate options
    # @param [Hash] opts Options of constructor
    # @raise [AclArgumentError]
    def validate_operators(opts)
      define_operator_and_ports(opts)

      if !PORT_OPERATE.key?(@operator)
        fail AclArgumentError, "Unknown operator: #{@operator}"
      elsif !valid_operator_and_port?
        fail AclArgumentError, 'Invalid port or ports sequence'
      end
    end

    # Varidate combination operator and port number
    # @return [Boolean]
    def valid_operator_and_port?
      case @operator
      when 'any'
        true
      when 'range'
        @begin_port &&
          @end_port &&
          @begin_port < @end_port
      else
        @begin_port
      end
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
