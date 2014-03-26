# -*- coding: utf-8 -*-
require 'cisco_acl_intp/ace'

module CiscoAclIntp
  # ACE for standard access list
  class StandardAce < AceBase
    # @param [String] value Action
    # @return [String]
    attr_accessor :action

    # @param [AceSrcDstSpec] value Source spec object
    # @return [AceSrcDstSpec]
    attr_accessor :src_spec

    # @param [AceLogSpec] value Log spec object
    # @return [AceLogSpec]
    attr_accessor :log_spec

    # Constructor
    # @param [Hash] opts Options
    # @option opts [Integer] :number Sequence number
    # @option opts [String] :action Action (permit/deny)
    # @option opts [AceSrcDstSpec] :src Source spec object
    # @option opts [Hash] :src Source spec parmeters
    # @option opts [AceLogSpec] :log Log spec object
    # @return [StandardAce]
    # @raise [AclArgumentError]
    def initialize(opts)
      super
      @options = opts
      @action = define_action
      @src_spec = define_src_spec
      @log_spec = define_log_spec
    end

    # @return [Boolean]
    def ==(other)
      @action == other.action && @src_spec == other.src_spec
    end

    # Generate string for Cisco IOS access list
    # @return [String]
    def to_s
      format(
        '%s %s %s',
        tag_action(@action.to_s),
        @src_spec,
        tag_other_qualifier(@log_spec ? @log_spec : '')
      )
    end

    # Search matched ACE
    # @param [StandardAce] other Target ACE
    # @return [Boolean] Matched or not
    def contains?(other)
      @src_spec.contains?(other.src_spec)
    end

    private

    # Set instance variables
    # @return [String] Action string
    # @raise [AclArgumentError]
    def define_action
      if @options.key?(:action)
        @options[:action]
      else
        fail AclArgumentError, 'Not specified action'
      end
    end

    # Set instance variables
    # @return [AceSrcDstSpec] Source spec object
    # @raise [AclArgumentError]
    def define_src_spec
      if @options.key?(:src)
        src = @options[:src]
        case src
        when Hash
          AceSrcDstSpec.new(src)
        when AceSrcDstSpec
          src
        else
          fail AclArgumentError, 'src spec: unknown class'
        end
      else
        fail AclArgumentError, 'Not specified src spec'
      end
    end

    # Set instance variables
    # @return [String] Log spec object
    # @raise [AclArgumentError]
    def define_log_spec
      @options[:log] || nil
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
