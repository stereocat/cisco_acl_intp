# frozen_string_literal: true

require 'forwardable'
require 'cisco_acl_intp/acespec_proto'
require 'cisco_acl_intp/acespec_port_opr'

module CiscoAclIntp
  # IP(TCP/UDP) port number and operator container
  class AcePortSpec < AceSpecBase
    extend Forwardable

    # @return [AcePortOperatorBase] value Port-set operator
    attr_reader :operator

    def_delegators :@operator, :begin_port, :port, :end_port, :to_s

    # Constructor
    # @param [Hash] opts Options
    # @option opts [String, Symbol] :operator Port operator,
    #   (any, strict_anyeq, neq, lt, gt, range)
    # @option opts [AceProtoSpecBase] :port Port (single/lower)
    #   (same as :begin_port, alias for unary operator)
    # @option opts [AceProtoSpecBase] :begin_port Port (single/lower)
    # @option opts [AceProtoSpecBase] :end_port Port (higher)
    # @raise [AclArgumentError]
    # @return [AcePortSpec]
    # @note '@begin_port' and '@end_port' should managed
    #   with port number and protocol name.
    #   it need the number when operate/compare protocol number,
    #   and need the name when stringize the object.
    # @todo in ACL, can "eq/neq" receive port list? IOS15 later?
    def initialize(opts)
      super()
      raise AclArgumentError, 'Not specified port operator' unless opts.key?(:operator)

      @options = opts
      define_operator_and_ports
    end

    # @param [AcePortSpec] other RHS Object
    # @return [Boolean]
    def ==(other)
      @operator == other.operator
    end

    # Check if self contains other port-set?
    # @param [AcePortSpec] other TCP/UDP Port spec
    # @raise [AclArgumentError]
    # @return [Boolean]
    def contains?(other)
      @operator.contains?(other.operator)
    end

    private

    # Port set operator table
    OPERATOR_CLASS = {
      strict_any: AcePortOpStrictAny,
      any: AcePortOpAny,
      eq: AcePortOpEq,
      neq: AcePortOpNeq,
      lt: AcePortOpLt,
      gt: AcePortOpGt,
      range: AcePortOpRange
    }.freeze

    # Set instance variables
    # @raise [AclArgumentError]
    # @return [AcePortOperatorBase] Port set operator object.
    def define_operator_and_ports
      opr = @options.key?(:operator) ? @options[:operator].intern : :any
      raise AclArgumentError, 'Unknown operator' unless OPERATOR_CLASS.key?(opr)

      @operator = OPERATOR_CLASS[opr].new(
        (@options[:port] || @options[:begin_port]),
        @options[:end_port]
      )
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
