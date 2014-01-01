# -*- coding: utf-8 -*-
require 'strscan'

module CiscoAclIntp

  # Lexical analyzer (Scanner)
  class Scanner

    # Scan ACL from file to parse
    # @param [File] file File name
    # @return [Array] Scanned tokens array
    def scan_file(file)
      # queue
      q = []

      file.each_line do | each |
        q.concat(scan_one_line(each))
      end
      q.push [false, 'EOF']

      q
    end

    # Scan ACL from variable
    # @param [String] str Access list string
    # @return [Array] Scanned tokens array
    def scan_line(str)
      q = []

      @curr_line = ''
      @old_line = ''

      str.split(/$/).each do | each |
        each.chomp!
        # add word separator at end of line
        each.concat(' ')
        q.concat(scan_one_line(each))
      end
      q.push [false, 'EOF']

      q
    end

    # Tokens that takes string parameter
    STRING_ARG_TOKENS = [
      ['remark', :leftover],
      ['description', :leftover],
      ['extended', :word],
      ['standard', :word],
      ['dynamic', :word],
      ['log-input', :word],
      ['log', :word],
      ['time-range', :word],
      ['reflect', :word],
      ['evaluate', :word],
      ['object-group', :word],
      ['object-group', 'network', :word],
      ['object-group', 'service', :word],
      ['group-object', :word],
    ]

    # STRING regexp:
    # first letter is alphabet or digit
    STR_REGEXP = '([a-zA-Z\d]\S*)'

    # Scan ACL
    # @param [String] line Access list string
    # @return [Array] Scanned tokens array
    def scan_one_line(line)
      @arg_tokens = gen_arg_token_lists # cache
      run_scanning(line)
    end # def scan_one_line

    private

    def run_scanning(line, q = [])
      ss = StringScanner.new(line)
      until ss.eos?
        case
        when scan_match_arg_tokens(ss, q)
        when scan_match_acl_header(ss, q)
        when scan_match_ipaddr(ss, q)
        when scan_match_common(ss, q, line)
        end
      end # until
      q.push [:EOS, nil] # Add end-of-string
    end

    def gen_arg_token_lists
      STRING_ARG_TOKENS.map do |set|
        set_dup = set.dup
        set_dup.map! do |each|
          case each
          when String
            '(' + each + ')'
          when Symbol
            case each
            when :word
              STR_REGEXP
            when :leftover
              '(.*)$'
            end
          end
        end
        [set_dup.join('\s+'), set.length]
      end
    end

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

    def scan_match_common(ss, q, line)
      case
      when ss.scan(/(\d+)\s/)
        ## Number
        q.push [:NUMBER, ss[1].to_i]
      when ss.scan(/#{STR_REGEXP}/)
        ## Tokens
        q.push [ss[1], ss[1]]
      else
        # NOT match
        q.push [:UNKNOWN, line]
      end
      ss.matched?
    end

    def scan_match_arg_tokens(ss, q)
      @arg_tokens.each do |(str, length)|
        if ss.scan(/#{str}/)
          (1...length).each do |idx|
            # puts "##{idx} : #{ss[idx]} : #{str}"
            q.push [ss[idx], ss[idx]]
          end
          # puts "##{length} : #{ss[length] }"
          q.push [:STRING, ss[length]] # last element
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
