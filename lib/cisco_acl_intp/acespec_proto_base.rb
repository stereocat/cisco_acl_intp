# frozen_string_literal: true

require 'cisco_acl_intp/acespec_base'

module CiscoAclIntp
  # IP/TCP/UDP protocol number and protocol name container base
  class AceProtoSpecBase < AceSpecBase
    include Comparable

    # @return [String] Protocol name
    attr_reader :name

    # @return [Integer] Protocol/Port number
    attr_reader :number

    # @return [Integer] Maximum protocol/port number
    attr_reader :max_num

    # @return [Symbol] L3/L4 protocol type
    attr_reader :protocol

    # Convert table of protocol number/name
    # @note Keys(protocol names) are String not as Symbol,
    #   because there are keys exists including '-'.
    DUMMY_PROTO_TABLE = {
      'any' => -1 # dummy
    }.freeze

    # Protocol Table
    # @return [Hash] Protocol table
    # @abstract
    def proto_table
      DUMMY_PROTO_TABLE
    end

    # Constructor
    # @param [String, Integer] proto_id Protocol ID (No. or Name)
    # @param [Integer] max_num Maximum protocol number.
    # @raise [AclArgumentError]
    # @return [AceProtoSpecBase]
    # @abstract
    # @note Variable '@protocol'
    #   should be assigned in inherited class constructor.
    def initialize(proto_id = nil, max_num = 255)
      super()
      @protocol = nil # must be defined in inherited class.
      @max_num = max_num

      case proto_id
      when /\d+/ # Integer-String, MUST check before 'String'
        define_param_by_integer(proto_id.to_i)
      when String # Not Integer-String
        define_param_by_string(proto_id)
      when Integer
        define_param_by_integer(proto_id)
      else
        raise AclArgumentError, "invalid protocol id #{proto_id}"
      end
    end

    # Check the port number in valid range of port number
    # @return [Boolean]
    def valid_range?
      (0..@max_num).cover?(@number)
    end

    # Check the port name is known or not.
    # @param [String] name IP/TCP/UDP port/protocol name
    # @return [Boolean]
    def valid_name?
      proto_table.key?(@name)
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      @name
    end

    # Return protocol/port number
    # @return [Integer] Protocol/Port number
    def to_i
      @number.to_i
    end

    # Compare by port number
    # @note Using "Comparable" module, '==' operator is defined by
    #   '<=>' operator. But '==' is overriden to compare instance
    #   equivalence instead of port number comparison.
    # @param [AceProtoSpecBase] other Compared instance
    # @return [Fixnum] Compare with protocol/port number
    def <=>(other)
      @number <=> other.to_i
    end

    # Check equality
    # @param [AceProtoSpecBase] other RHS object.
    # @return [Boolean] Compare with protocol/port number
    def ==(other)
      @protocol == other.protocol &&
        @name == other.name &&
        @number == other.number
    end

    # Check if port/protocol number is minimum.
    # @return [Boolean]
    def min?
      @number.zero?
    end

    # Check if port/protocol number is maximum.
    # @return [Boolean]
    def max?
      @number == @max_num
    end

    private

    # Convert protocol/port number to string (its name)
    # @return [String] Name of protocol/port number.
    #   If does not match the number in IOS proto/port literal,
    #   return number.to_s string
    def number_to_name
      proto_table.invert[@number] || @number.to_s
    end

    # Convert protocol/port name to number
    # @raise [AclArgumentError]
    def name_to_number
      raise AclArgumentError, "Unknown protocol name: #{@name}" unless proto_table.key?(@name)

      proto_table[@name]
    end

    # @param [String] name Protocol name.
    # @raise [AclArgumentError]
    def define_param_by_string(name)
      @name = name
      raise AclArgumentError, "Unknown protocol name: #{@name}" unless valid_name?

      @number = name_to_number
    end

    # @param [Integer] number Protocol No.
    # @raise [AclArgumentError]
    def define_param_by_integer(number)
      @number = number
      raise AclArgumentError, "Invalid protocol number: #{@number}" unless valid_range?

      @name = number_to_name
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
