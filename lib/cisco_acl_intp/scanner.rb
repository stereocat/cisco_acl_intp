# frozen_string_literal: true

require 'strscan'
require 'cisco_acl_intp/scanner_special_token_handler'

module CiscoAclIntp
  # Lexical analyzer (Scanner)
  class Scanner
    # include special tokens data and its handlers
    include SpecialTokenHandler

    # Constructor
    # @return [Scanner]
    def initialize
      @arg_tokens = gen_arg_token_lists
    end

    # Scan ACL from file to parse
    # @param [File] file File IO object
    # @return [Array] Scanned tokens array (Queue)
    def scan_file(file)
      run_scaner(file) do
        # no-op
      end
    end

    # Scan ACL from variable
    # @param [String] str Access list string
    # @return [Array] Scanned tokens array (Queue)
    def scan_line(str)
      run_scaner(str) do |each|
        each.chomp!
        # add word separator at end of line
        each.concat(' ')
      end
    end

    private

    # Exec scanning
    # @param [File, String] acl_text ACL data text
    # @yield Pre-process of scanning a line
    # @yieldparam [String] each Each line of acl_text
    #   (called by `each_line` methods)
    # @return [Array] Scanned tokens array (Queue)
    def run_scaner(acl_text)
      queue = []
      acl_text.each_line do |each|
        yield(each)
        queue.concat(scan_one_line(each))
      end
      queue.push [false, 'EOF']
    end

    # Scan a line
    # @param [String] line ACL String
    # @return [Array] Scanned tokens array (Queue)
    def scan_one_line(line)
      @ss = StringScanner.new(line)
      @line_queue = []
      scan_match_arg_tokens || scan_match_acl_header || scan_match_ipaddr || scan_match_common until @ss.eos?
      @line_queue.push [:EOS, nil] # Add end-of-string
    end

    # Numbered ACL header checker
    # @param [Integer] aclnum ACL number
    # @return [Array] Token list
    def check_numd_acl_type(aclnum)
      case aclnum
      when 1..99, 1300..1999
        [:NUMD_STD_ACL, aclnum]
      when 100..199, 2000..2699
        [:NUMD_EXT_ACL, aclnum]
      else
        [:UNKNOWN, "access-list #{aclnum}"]
      end
    end

    # Scanner of acl header
    # @return [Boolean] if line matched acl header
    def scan_match_acl_header
      if @ss.scan(/\s*!.*$/) || @ss.scan(/\s*#.*$/)
        ## "!/# comment" and whitespace line, NO-OP
      elsif @ss.scan(/\s+/) || @ss.scan(/\A\s*\Z/)
        ## whitespace, NO-OP
        # @line_queue.push [:WHITESPACE, ""] # for debug
      elsif @ss.scan(/(?:access-list)\s+(\d+)\s/)
        ## Numbered ACL Header
        ## numbered acl has no difference
        ## in format between Standard and Extended...
        @line_queue.push check_numd_acl_type(@ss[1].to_i)
      elsif @ss.scan(/(ip\s+access-list)\s/)
        ## Named ACL Header
        @line_queue.push [:NAMED_ACL, @ss[1]]
      end
      @ss.matched?
    end

    # Scanner of IP address
    # @return [Boolean] if line matched IP address
    def scan_match_ipaddr
      if @ss.scan(/(\d+\.\d+\.\d+\.\d+)\s/)
        ## IP Address
        @line_queue.push [:IPV4_ADDR, @ss[1]]
      elsif @ss.scan(%r{(\d+\.\d+\.\d+\.\d+)(/)(\d+)\s})
        ## IP Address of 'ip/mask' notation
        @line_queue.push [:IPV4_ADDR, @ss[1]]
        @line_queue.push ['/',        @ss[2]]
        @line_queue.push [:NUMBER,    @ss[3].to_i]
      end
      @ss.matched?
    end

    # Scanner of common tokens
    # @return [Boolean] if line matched tokens
    def scan_match_common
      if @ss.scan(/(\d+)\s/)
        ## Number
        @line_queue.push [:NUMBER, @ss[1].to_i]
      elsif @ss.scan(/([+\-]?#{STR_REGEXP})/)
        ## Tokens (echo back)
        ## defined in module SpecialTokenHandler
        ## plus/minus used in tcp flag token e.g. +syn -ack
        @line_queue.push token_list(@ss[1])
      else
        ## do not match any?
        ## then scanned whole line and
        ## put in @line_queue as unknown.
        @ss.scan(/(.*)$/) # match all
        @line_queue.push [:UNKNOWN, @ss[1]]
      end
      @ss.matched?
    end

    # Scanner of special tokens
    # @return [Boolean] if line matched tokens
    def scan_match_arg_tokens
      @arg_tokens.each do |(str, length)|
        next unless @ss.scan(/#{str}/)

        (1...length).each do |idx|
          @line_queue.push token_list(@ss[idx])
        end
        @line_queue.push [:STRING, @ss[length]] # last element
      end
      @ss.matched?
    end

    # Generate echo-backed token array
    # @param [String] token Token
    # @return [Array] Token array for scanner queue
    def token_list(token)
      [token, token]
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
