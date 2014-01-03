# -*- coding: utf-8 -*-
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
    # @param [File] file File name
    # @return [Array] Scanned tokens array (Queue)
    def scan_file(file)
      q = [] # queue
      file.each_line do |each|
        q.concat(scan_one_line(each))
      end
      q.push [false, 'EOF']
    end

    # Scan ACL from variable
    # @param [String] str Access list string
    # @return [Array] Scanned tokens array (Queue)
    def scan_line(str)
      q = [] # queue
      str.split(/$/).each do |each|
        each.chomp!
        # add word separator at end of line
        each.concat(' ')
        q.concat(scan_one_line(each))
      end
      q.push [false, 'EOF']
    end

    # Scan ACL
    # @param [String] line Access list string
    # @return [Array] Scanned tokens array (Queue)
    def scan_one_line(line)
      run_scanning(line)
    end # def scan_one_line

    private

    # Scan a line
    # @param [String] line ACL String
    # @param [Array] q Queue
    # @return [Array] Scanned tokens array (Queue)
    def run_scanning(line, q = [])
      ss = StringScanner.new(line)
      until ss.eos?
        case
        when scan_match_arg_tokens(ss, q)
        when scan_match_acl_header(ss, q)
        when scan_match_ipaddr(ss, q)
        else scan_match_common(ss, q)
        end
      end
      q.push [:EOS, nil] # Add end-of-string
    end

    # Numbered ACL header checker
    # @param [Integer] aclnum ACL number
    # @return [Array] Token list
    def check_numd_acl_type(aclnum)
      if (1 <= aclnum && aclnum <= 99) ||
          (1300 <= aclnum && aclnum <= 1999)
        [:NUMD_STD_ACL, aclnum]
      elsif (100 <= aclnum && aclnum <= 199) ||
          (2000 <= aclnum && aclnum <= 2699)
        [:NUMD_EXT_ACL, aclnum]
      else
        [:UNKNOWN, "access-list #{aclnum}"]
      end
    end

    # Scanner of acl header
    # @param [StringScanner] ss Scanned ACL line
    # @param [Array] q Queue
    # @return [Boolean] if line matched acl header
    def scan_match_acl_header(ss, q)
      case
      when ss.scan(/\s*!.*$/), ss.scan(/\s*#.*$/)
        ## "!/# comment" and whitespace line, NO-OP
      when ss.scan(/\s+/), ss.scan(/\A\s*\Z/)
        ## whitespace, NO-OP
        # q.push [:WHITESPACE, ""] # for debug
      when ss.scan(/(?:access-list)\s+(\d+)\s/)
        ## Numbered ACL Header
        ## numbered acl has no difference
        ## in format between Standard and Extended...
        q.push check_numd_acl_type(ss[1].to_i)
      when ss.scan(/(ip\s+access\-list)\s/)
        ## Named ACL Header
        q.push [:NAMED_ACL, ss[1]]
      end
      ss.matched?
    end

    # Scanner of IP address
    # @param [StringScanner] ss Scanned ACL line
    # @param [Array] q Queue
    # @return [Boolean] if line matched IP address
    def scan_match_ipaddr(ss, q)
      case
      when ss.scan(/(\d+\.\d+\.\d+\.\d+)\s/)
        ## IP Address
        q.push [:IPV4_ADDR, ss[1]]
      when ss.scan(/(\d+\.\d+\.\d+\.\d+)(\/)(\d+)\s/)
        ## IP Address of 'ip/mask' notation
        q.push [:IPV4_ADDR, ss[1]]
        q.push ['/',        ss[2]]
        q.push [:NUMBER,    ss[3].to_i]
      end
      ss.matched?
    end

    # Scanner of common tokens
    # @param [StringScanner] ss Scanned ACL line
    # @param [Array] q Queue
    # @return [Boolean] if line matched tokens
    def scan_match_common(ss, q)
      case
      when ss.scan(/(\d+)\s/)
        ## Number
        q.push [:NUMBER, ss[1].to_i]
      when ss.scan(/([\+\-]?#{STR_REGEXP})/)
        ## Tokens (echo back)
        ## defined in module SpecialTokenHandler
        ## plus/minus used in tcp flag token e.g. +syn -ack
        q.push [ss[1], ss[1]]
      else
        ## do not match any?
        ## then scanned whole line and
        ## put in queue as unknown.
        ss.scan(/(.*)$/) # match all
        q.push [:UNKNOWN, ss[1]]
      end
      ss.matched?
    end

    # Scanner of special tokens
    # @param [StringScanner] ss Scanned ACL line
    # @param [Array] q Queue
    # @return [Boolean] if line matched tokens
    def scan_match_arg_tokens(ss, q)
      @arg_tokens.each do |(str, length)|
        if ss.scan(/#{str}/)
          (1...length).each do |idx|
            q.push [ss[idx], ss[idx]]
          end
          q.push [:STRING, ss[length]] # last element
          break
        end
      end
      ss.matched?
    end

  end # class Scanner

end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
