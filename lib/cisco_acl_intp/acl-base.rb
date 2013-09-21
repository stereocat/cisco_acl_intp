require 'term/ansicolor'

module CiscoAclIntp

  # Standard Error Handler of CiscoAclParser
  class AclError < StandardError; end

  # Argument Error Handler of CiscoAclParser
  class AclArgumentError < AclError; end

  # Acl container common utility and status management
  class AclContainerBase
    include Term::ANSIColor

    # color mode
    @@color = false

    # Enables coloring
    def self.enable_color
      @@color = true
    end

    # Disables coloring
    def self.disable_color
      @@color = false
    end

    # Generate string for Cisco IOS access list
    # @abstract
    # @return [String]
    def to_s
      raise AclError, "Not overridden AclContainerBase::to_s"
    end

    private

    # Generate string using colors
    # @param [String] str String
    # @param [Array<String>] pre_c Color attribute(s) (put before 'str')
    # @return [String] Colored string (if enabled [@@color])
    def c_str str, *pre_c
      if pre_c and @@color
        pre_c.concat [str, clear]
        pre_c.join
      else
        str
      end
    end

    # Access list header
    # @param [String] str String
    # @return [String] Colored string
    def c_hdr str
      c_str str, on_blue
    end

    # Named access list type
    # @param [String] str String
    # @return [String] Colored string
    def c_type str
      c_str str, underline
    end

    # Action
    # @param [String] str String
    # @return [String] Colored string
    def c_act str
      c_str str, intense_magenta
    end

    # User defined name/number
    # @param [String] str String
    # @return [String] Colored string
    def c_name str
      c_str str, bold
    end

    # Remark
    # @param [String] str String
    # @return [String] Colored string
    def c_rmk str
      c_str str, blink
    end

    # IP address
    # @param [String] str String
    # @return [String] Colored string
    def c_ip str
      c_str str, green, underline
    end

    # Wildcard mask
    # @param [String] str String
    # @return [String] Colored string
    def c_mask str
      c_str str, yellow
    end

    # Protocol and port
    # @param [String] str String
    # @return [String] Colored string
    def c_pp str
      c_str str, cyan
    end

  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
