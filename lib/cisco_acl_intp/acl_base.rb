# -*- coding: utf-8 -*-

require 'term/ansicolor'

module CiscoAclIntp
  # Standard Error Handler of CiscoAclParser
  class AclError < StandardError; end

  # Argument Error Handler of CiscoAclParser
  class AclArgumentError < AclError; end

  # Acl container common utility and status management
  class AclContainerBase
    class << self
      # Color mode: defined as a class instance variable
      attr_accessor :color_mode
    end

    # Disables coloring
    def self.disable_color
      @color_mode = :none
    end

    # Generate string for Cisco IOS access list
    # @abstract
    # @return [String]
    def to_s
      raise AclError, 'Not overridden AclContainerBase::to_s'
    end

    private

    # Table of ACL Tag color codes for terminal
    TERM_COLOR_TABLE = {
      header: Term::ANSIColor.on_blue,
      type: Term::ANSIColor.underline,
      action: Term::ANSIColor.intense_magenta,
      name: Term::ANSIColor.bold,
      remark: Term::ANSIColor.blink,
      ip: [Term::ANSIColor.green, Term::ANSIColor.underline].join,
      mask: Term::ANSIColor.yellow,
      protocol: Term::ANSIColor.cyan,
      port: Term::ANSIColor.cyan,
      other_qualifier: Term::ANSIColor.green,
      error: [Term::ANSIColor.red, Term::ANSIColor.bold].join
    }.freeze

    # Generate header of ACL tag
    # @param [Symbol] tag Tag symbol.
    # @return [String] Tagged string.
    def generate_tag_header(tag)
      case AclContainerBase.color_mode
      when :term
        TERM_COLOR_TABLE[tag]
      when :html
        %(<span class="acltag_#{tag}">)
      else
        ''
      end
    end

    # Generate footer of ACL tag
    # @return [String] Tagged string.
    def generate_tag_footer
      case AclContainerBase.color_mode
      when :term
        Term::ANSIColor.clear
      when :html
        '</span>'
      else
        ''
      end
    end

    # Generate tagged ACL string.
    # @param [Symbol] tag Tag symbol.
    # @param [Array] args Array of argments.
    # @return [String] Tagged string.
    def generate_tagged_str(tag, *args)
      tag_head = generate_tag_header(tag)
      tag_body = args.join
      tag_foot = generate_tag_footer
      [tag_head, tag_body, tag_foot].join
    end

    # acl string clean-up
    # @param [String] str ACL string.
    # @return [String]
    def clean_acl_string(str)
      str.strip.gsub(/\s+/, ' ')
    end

    # Generate tagging method dynamically.
    # @raise [NoMethodError]
    def method_missing(name, *args)
      name.to_s =~ /^tag_(.+)$/ && tag = Regexp.last_match(1).intern
      if TERM_COLOR_TABLE.key?(tag)
        generate_tagged_str(tag, *args)
      else
        super
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
