# -*- coding: utf-8 -*-
require 'strscan'

module CiscoAclIntp

  # Data and Handler functions of special tokens
  module SpecialTokenMgr

    # STRING token regexp:
    # first letter is alphabet or digit
    STR_REGEXP = '[a-zA-Z\d]\S*'

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
      ['object-group', 'network', :word],
      ['object-group', 'service', :word],
      ['object-group', :word], # longest match
      ['group-object', :word],
    ]

    # Convert STRING_ARG_TOKENS symbol
    #   to Regexp String
    # @param [Symbol] symbol :STRING symbol
    # @return [String] Regexp string
    def conver_symbol_to_regexpstr(symbol)
      case symbol
      when :word
        '(' + STR_REGEXP + ')'
      when :leftover
        '(.*)$'
      end
    end

    # Convert STRING_ARG_TOKENS to Regexp string
    # @param [Array] set Special tokens set
    # @returns [String] Regexp string
    def convert_tokens_to_regexpstr(set)
      # puts "## set #{set}"
      set.map do |each|
        case each
        when String
          '(' + each + ')'
        when Symbol
          conver_symbol_to_regexpstr(each)
        end
      end
    end

    # Generate regexp string list for scanner
    # @return [Array] set of regexp and number of token
    def gen_arg_token_lists
      STRING_ARG_TOKENS.map do |each|
        re_str_list = convert_tokens_to_regexpstr(each)
        # puts "### #{re_str_list}"
        [re_str_list.join('\s+'), each.length]
      end
    end

  end # module SpecialTokenMgr

end # module CiscoAclIntp

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
