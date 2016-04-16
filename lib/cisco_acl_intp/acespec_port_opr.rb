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

    # Specified port-set is contained or not?
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def contains?(other)
      other.is_a?(AcePortOperatorBase) # match any conditions
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      # no need to print tcp/udp ANY in Cisco ACL
      ''
    end
  end

  # SSTRICT-ANY operator class
  class AcePortOpStrictAny < AcePortOpAny
    # Constructor
    def initialize(*args)
      super
      @operator = :strict_any
    end

    # Specified port-set is contained or not?
    # @param [AcePortOperator] other Another operator
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

    # Specified port-set is contained or not?
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def contains?(other)
      case other
      when AcePortOpEq
        other.port == @begin_port
      else
        contains_default(other)
      end
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

    # Operate EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_eq(other)
      other.port != @begin_port
    end

    # Operate NOT_EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_neq(other)
      other.port == @begin_port
    end

    # Operate LOWER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_lt(other)
      other.port <= @begin_port
    end

    # Operate GREATER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_gt(other)
      @begin_port <= other.port
    end

    # Operate RANGE containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_range(other)
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

    # Operate EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_eq(other)
      other.port < @begin_port
    end

    # Operate NOT_EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_neq(other)
      other.port.max? && @begin_port.max?
    end

    # Operate LOWER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_lt(other)
      other.port <= @begin_port
    end

    # Operate RANGE containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_range(other)
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

    # Operate EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_eq(other)
      @begin_port < other.port
    end

    # Operate NOT_EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_neq(other)
      @begin_port.min? && other.port.min?
    end

    # Operate GREATER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_gt(other)
      @begin_port <= other.port
    end

    # Operate RANGE containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_range(other)
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

    # Operate EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_eq(other)
      @begin_port <= other.port && other.port <= @end_port
    end

    # Operate NOT_EQUAL containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_neq(other)
      @begin_port.min? && @end_port.max? &&
        (other.port.min? || other.port.max?)
    end

    # Operate LOWER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_lt(other)
      @begin_port.min? && other.port < @end_port
    end

    # Operate GREATER_THAN containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_gt(other)
      @begin_port < other.port && @end_port.max?
    end

    # Operate RANGE containing check
    # @param [AcePortOperator] other Another operator
    # @return [Boolean]
    def compare_range(other)
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
