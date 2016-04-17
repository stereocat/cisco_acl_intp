# -*- coding: utf-8 -*-
require 'cisco_acl_intp/acc'

module CiscoAclIntp
  # TCP/UDP Port Set Operator Class
  class AcePortOperatorBase < AceSpecBase
    # @return
    attr_reader :operator

    # @param [AceProtoSpecBase] value Port No. (single/lower)
    # @return [AceProtoSpecBase]
    attr_reader :begin_port
    # alias for unary operator
    alias port begin_port

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
        contains_eq?(other)
      when AcePortOpNeq
        contains_neq?(other)
      when AcePortOpLt
        contains_lt?(other)
      when AcePortOpGt
        contains_gt?(other)
      when AcePortOpRange
        contains_range?(other)
      else
        check_any_operator(other)
      end
    end

    private

    # ANY operator check
    # @param [AcePortOpAny] other Another operator
    # @return [Boolean]
    def check_any_operator(other)
      case other
      when AcePortOpStrictAny
        # must match before AcePortOpAny (Base Class)
        contains_strict_any?(other)
      when AcePortOpAny
        contains_any?(other)
      else
        false # unknown operator
      end
    end

    # Operate ANY containing check
    # @param [AcePortOpAny] _other Another operator
    # @return [Boolean]
    def contains_any?(_other)
      false
    end

    # Operate STRICT_ANY containing check
    # @param [AcePortOpStrictAny] _other Another operator
    # @return [Boolean]
    def contains_strict_any?(_other)
      false
    end

    # Operate EQUAL containing check
    # @param [AcePortOpEq] _other Another operator
    # @return [Boolean]
    def contains_eq?(_other)
      false
    end

    # Operate NOT_EQUAL containing check
    # @param [AcePortOpNeq] _other Another operator
    # @return [Boolean]
    def contains_neq?(_other)
      false
    end

    # Operate LOWER_THAN containing check
    # @param [AcePortOpLt] _other Another operator
    # @return [Boolean]
    def contains_lt?(_other)
      false
    end

    # Operate GREATER_THAN containing check
    # @param [AcePortOpGt] _other Another operator
    # @return [Boolean]
    def contains_gt?(_other)
      false
    end

    # Operate RANGE containing check
    # @param [AcePortOpRange] _other Another operator
    # @return [Boolean]
    def contains_range?(_other)
      false
    end
  end

  # Unary operator base class
  class AceUnaryOpBase < AcePortOperatorBase
    # Constructor
    def initialize(*args)
      super
      if @begin_port.nil?
        raise AclArgumentError, 'Port did not specified in unary operator'
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
