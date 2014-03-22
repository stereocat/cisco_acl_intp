# -*- coding: utf-8 -*-
require 'cisco_acl_intp/acl_base'

module CiscoAclIntp
  # TCP/UDP Port Set Operator Class
  class AcePortOperatorBase < AclContainerBase
    # @return
    attr_reader :operator

    # @param [AceProtoSpecBase] value Port No. (single/lower)
    # @return [AceProtoSpecBase]
    attr_reader :begin_port
    # alias for unary operator
    alias_method :port, :begin_port

    # @param [AceProtoSpecBase] value Port No. (higher)
    # @return [AceProtoSpecBase]
    attr_reader :end_port

    # Constructor
    # @param [AceProtoSpecBase] begin_port Begin port object.
    # @param [AceProtoSpecBase] end_port End port object.
    # @raise [AclArgumentError]
    def initialize(begin_port, end_port = nil)
      @operator = :any # default
      @begin_port = begin_port
      @end_port = end_port
    end

    # Check equality
    # @param [AceProtoSpecBase] other RHS object.
    # @return [Boolean]
    def ==(other)
      @operator == other.operator &&
        @begin_port == other.begin_port &&
        @end_port == other.end_port
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      tag_port(
        clean_acl_string(
          format('%s %s %s', @operator, @begin_port, @end_port)
        )
      )
    end

    # Specified port-set is contained or not?
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def contains?(other)
      case other
      when AcePortOpEq
        compare_eq(other)
      when AcePortOpNeq
        compare_neq(other)
      when AcePortOpLt
        compare_lt(other)
      when AcePortOpGt
        compare_gt(other)
      when AcePortOpRange
        compare_range(other)
      else
        contains_default(other)
      end
    end

    private

    # Operate EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_eq(other)
      false
    end

    # Operate NOT_EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_neq(other)
      false
    end

    # Operate LOWER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_lt(other)
      false
    end

    # Operate GREATER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_gt(other)
      false
    end

    # Operate RANGE containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_range(other)
      false
    end

    # Operate *ANY containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def contains_default(other)
      case other
      when AcePortOpAny
        true
      when AcePortOpStrictAny
        false
      else
        false
      end
    end
  end

  # Unary operator base class
  class AceUnaryOpBase < AcePortOperatorBase
    # Constructor
    def initialize(*args)
      super
      if @begin_port.nil?
        fail AclArgumentError, 'Port did not specified in unary operator'
      end
      @end_port = nil
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
