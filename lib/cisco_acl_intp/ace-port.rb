# -*- coding: utf-8 -*-

require 'forwardable'
require 'cisco_acl_intp/ace-proto'

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
    def initialize opts

      ## TBD
      ## ACL において eq/neq はポートのリストをうけとることができる??
      ## IOS15以降?

      if opts[:operator]
        @operator = opts[:operator]
        @port1 = opts[:port1] or nil
        @port2 = opts[:port2] or nil

        if ( not @port1 ) and ( @operator != 'any' )
          raise AclArgumentError, "Not specified port_1"
        end

        if opts[:port2] && ( opts[:port1] > opts[:port2] )
          raise AclArgumentError, "Not specified port_2 or Invalid port range args sequence"
        end
      else
        raise AclArgumentError, "Not specified port operator"
      end
    end

    # @param [AcePortSpec] other RHS Object
    # @return [Boolean]
    def == other
      @operator == other.operator and
        @port1 == other.port1 and
        @port2 == other.port2
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      if @operator == 'any'
        ""
      else
        c_pp(
          sprintf(
            "%s %s %s",
            @operator ? @operator : "",
            @port1 ? @port1 : "",
            @port2 ? @port2 : ""
          )
        )
      end
    end

    # Check the port number matches this?
    # @param [Integer] port TCP/UDP Port number
    # @raise [AclArgumentError]
    # @return [Boolean]
    def matches? port
      if not valid_range?( port )
        raise AclArgumentError, "Port out of range: #{ port }"
      end

      ## TBD
      ## operator は symbol で指定すべきでは?

      case @operator
      when 'any'   then true
      when 'eq'    then @port1.to_i == port
      when 'neq'   then @port1.to_i != port
      when 'gt'    then @port1.to_i <  port
      when 'lt'    then @port1.to_i >  port
      when 'range' then @port1.to_i <= port && port <= @port2.to_i
      else              false
      end
    end
  end

end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
