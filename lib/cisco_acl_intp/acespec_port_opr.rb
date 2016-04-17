# -*- coding: utf-8 -*-
require 'cisco_acl_intp/acespec_port_opr_base'

module CiscoAclIntp
  # ANY operator class
  class AcePortOpAny < AceUnaryOpBase
    # Constructor
    def initialize(*_args)
      @begin_port = nil
      @end_port = nil
      @operator = :any
    end

    # ANY contains other_port? (always true)
    # @param [AcePortOperatorBase] _other Another operator
    # @return [Boolean]
    def contains?(_other)
      true
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      # no need to print tcp/udp ANY in Cisco ACL
      ''
    end
  end

  # STRICT-ANY operator class
  class AcePortOpStrictAny < AcePortOpAny
    # Constructor
    def initialize(*args)
      super
      @operator = :strict_any
    end

    # STRICT_ANY contains other_port?
    # @param [AcePortOperatorBase] other Another operator
    # @return [Boolean]
    def contains?(other)
      case other
      when AcePortOpAny, AcePortOpStrictAny
        true
      else
        false
      end
    end
  end

  # EQUAL operator class
  class AcePortOpEq < AceUnaryOpBase
    # Constructor
    def initialize(*args)
      super
      @operator = :eq
    end

    # EQ contains EQ?
    # @param [AcePortOpEq] other Another operator
    # @return [Boolean]
    def contains_eq?(other)
      other.port == @begin_port
    end
  end

  # NOT_EQUAL operator class
  class AcePortOpNeq < AceUnaryOpBase
    # Constructor
    def initialize(*args)
      super
      @operator = :neq
    end

    private

    # NEQ contains EQ?
    # @param [AcePortOpEq] other Another operator
    # @return [Boolean]
    def contains_eq?(other)
      other.port != @begin_port
    end

    # NEQ contains NEQ?
    # @param [AcePortOpNeq] other Another operator
    # @return [Boolean]
    def contains_neq?(other)
      other.port == @begin_port
    end

    # NEQ contains LT?
    # @param [AcePortOpLt] other Another operator
    # @return [Boolean]
    def contains_lt?(other)
      other.port <= @begin_port
    end

    # NEQ contains GT?
    # @param [AcePortOpGt] other Another operator
    # @return [Boolean]
    def contains_gt?(other)
      @begin_port <= other.port
    end

    # NEQ contains RANGE?
    # @param [AcePortOpRange] other Another operator
    # @return [Boolean]
    def contains_range?(other)
      other.end_port < @begin_port || @begin_port < other.begin_port
    end
  end

  # LOWER_THAN operator class
  class AcePortOpLt < AceUnaryOpBase
    # Constructor
    def initialize(*args)
      super
      @operator = :lt
    end

    private

    # LT contains EQ?
    # @param [AcePortOpEq] other Another operator
    # @return [Boolean]
    def contains_eq?(other)
      other.port < @begin_port
    end

    # LT contains NEQ?
    # @param [AcePortOpNeq] other Another operator
    # @return [Boolean]
    def contains_neq?(other)
      other.port.max? && @begin_port.max?
    end

    # LT contains LT?
    # @param [AcePortOpLt] other Another operator
    # @return [Boolean]
    def contains_lt?(other)
      other.port <= @begin_port
    end

    # LT contains RANGE?
    # @param [AcePortOpRange] other Another operator
    # @return [Boolean]
    def contains_range?(other)
      other.end_port < @begin_port
    end
  end

  # GREATER_THAN operator class
  class AcePortOpGt < AceUnaryOpBase
    # Constructor
    def initialize(*args)
      super
      @operator = :gt
    end

    private

    # GT contains EQ?
    # @param [AcePortOpEq] other Another operator
    # @return [Boolean]
    def contains_eq?(other)
      @begin_port < other.port
    end

    # GT contains NEQ?
    # @param [AcePortOpNeq] other Another operator
    # @return [Boolean]
    def contains_neq?(other)
      @begin_port.min? && other.port.min?
    end

    # GT contains GT?
    # @param [AcePortOpGt] other Another operator
    # @return [Boolean]
    def contains_gt?(other)
      @begin_port <= other.port
    end

    # GT contains RANGE?
    # @param [AcePortOperatorBase] other Another operator
    # @return [Boolean]
    def contains_range?(other)
      @begin_port < other.begin_port
    end
  end

  # RANGE operator class
  class AcePortOpRange < AcePortOperatorBase
    # Constructor
    def initialize(*args)
      super
      unless @begin_port < @end_port
        raise AclArgumentError, 'Invalid port sequence'
      end
      @operator = :range
    end

    private

    # RANGE contains ANY?
    # @param [AcePortOpAny] _other Another operator
    # @return [Boolean]
    def contains_any?(_other)
      @begin_port.min? && @end_port.max?
    end

    # RANGE contains EQ?
    # @param [AcePortOpEq] other Another operator
    # @return [Boolean]
    def contains_eq?(other)
      @begin_port <= other.port && other.port <= @end_port
    end

    # RANGE contains NEQ?
    # @param [AcePortOpNeq] other Another operator
    # @return [Boolean]
    def contains_neq?(other)
      @begin_port.min? && @end_port.max? &&
        (other.port.min? || other.port.max?)
    end

    # RANGE contains LT?
    # @param [AcePortOpLt] other Another operator
    # @return [Boolean]
    def contains_lt?(other)
      @begin_port.min? && other.port < @end_port
    end

    # RANGE contains GT?
    # @param [AcePortOpGt] other Another operator
    # @return [Boolean]
    def contains_gt?(other)
      @begin_port < other.port && @end_port.max?
    end

    # RANGE contains RANGE?
    # @param [AcePortOpRange] other Another operator
    # @return [Boolean]
    def contains_range?(other)
      @begin_port <= other.begin_port &&
        other.end_port <= @end_port
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
