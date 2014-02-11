# -*- coding: utf-8 -*-

require 'cisco_acl_intp/ace_proto'

module CiscoAclIntp
  # IP(TCP/UDP) port number and operator container
  class AcePortSpec < AclContainerBase
    include AceTcpUdpPortValidation

    # @param [String] value Operator of port (eq/neq/gt/lt/range)
    # @return [String]
    attr_reader :operator

    # @param [Symbol] value Protocol name [:tcp, :udp]
    # @return [String]
    attr_reader :protocol

    # @param [AceProtoSpecBase] value Port No. (single/lower)
    # @return [AceProtoSpecBase]
    attr_reader :begin_port

    # alias for unary operator
    alias_method :port, :begin_port

    # @param [AceProtoSpecBase] value Port No. (higher)
    # @return [AceProtoSpecBase]
    attr_reader :end_port

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
    # @todo in ACL, can "eq/neq" receive port list? IOS15 later?
    def initialize(opts)
      @protocol = :ip
      if opts.key?(:operator)
        @options = opts
        validate_operators
      else
        fail AclArgumentError, 'Not specified port operator'
      end
    end

    # @param [AcePortSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @protocol == other.protocol &&
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
        tag_port(
          clean_acl_string(
            sprintf('%s %s %s', @operator, @begin_port, @end_port)
          )
        )
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
      end
    }

    # Check the port number matches this?
    # @param [Integer,String] port TCP/UDP Port No./Name
    # @raise [AclArgumentError]
    # @return [Boolean]
    def matches?(port)
      port = case port
             when String
               if port =~ /\d+/
                 port.to_i
               else
                 convert_proto_spec_by_name(port)
               end
             else
               port
             end
      unless valid_range?(port.to_i)
        fail AclArgumentError, "Port out of range: #{port}"
      end
      # @operator was validated in constructor
      PORT_OPERATE[@operator].call(@begin_port.to_i, @end_port.to_i, port.to_i)
    end

    private

    # Convert from port name to AceProtoSpecBase object
    # @param [String] name TCP/UDP Port Name
    # @raise [AclArgumentError]
    # @return [AceProtoSpecBase]
    def convert_proto_spec_by_name(name)
      fail AclArgumentError, sprintf(
        'Cannot judge port name: %s, w/protocol: %s',
        @name, @protocol
      )
    end

    # Set instance variables
    def define_operator_and_ports
      @operator = @options[:operator] || 'any'
      @begin_port = @options[:port] || @options[:begin_port] || nil
      @end_port = @options[:end_port] || nil
    end

    # Varidate options
    # @raise [AclArgumentError]
    def validate_operators
      define_operator_and_ports

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
  end # class AcePortSpec

  # TCP port number and operator container
  class AceTcpPortSpec < AcePortSpec
    # Constructor
    # @see AcePortSpec#initialize
    def initialize(opts)
      super
      @protocol = :tcp
    end

    private

    # Convert from port name to AceTcpProtoSpecBase object
    # @param [String] name TCP Port Name
    # @raise [AclArgumentError]
    # @return [AceTcpProtoSpec]
    def convert_proto_spec_by_name(name)
      AceTcpProtoSpec.new(name: name)
    end
  end # class AceTcpPortSpec

  # UDP port number and operator container
  class AceUdpPortSpec < AcePortSpec
    # Constructor
    # @see AcePortSpec#initialize
    def initialize(opts)
      super
      @protocol = :udp
    end

    private

    # Convert from port name to AceUdpProtoSpecBase object
    # @param [String] name UDP Port Name
    # @raise [AclArgumentError]
    # @return [AceUdpProtoSpec]
    def convert_proto_spec_by_name(name)
      AceUdpProtoSpec.new(name: name)
    end
  end # class AceUdpPortSpec
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
