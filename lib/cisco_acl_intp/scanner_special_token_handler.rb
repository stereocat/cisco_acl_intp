# frozen_string_literal: true

require 'strscan'

module CiscoAclIntp
  # Data and Handler functions of special tokens
  module SpecialTokenHandler
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
      ['group-object', :word]
    ].freeze

    # Conversion table of string-tokens
    SYMBOL_TO_REGEXPSTR = {
      word: ['(', STR_REGEXP, ')'].join,
      leftover: '(.*)$'
    }.freeze

    # Convert STRING_ARG_TOKENS to Regexp string
    # @param [Array] set Special tokens set
    # @return [String] Regexp string
    def convert_tokens_to_regexpstr(set)
      set.map do |each|
        case each
        when String
          "(#{each})"
        when Symbol
          SYMBOL_TO_REGEXPSTR[each]
        end
      end
    end

    # Generate regexp string list for scanner
    # @return [Array] set of regexp and number of token
    def gen_arg_token_lists
      STRING_ARG_TOKENS.map do |each|
        re_str_list = convert_tokens_to_regexpstr(each)
        [re_str_list.join('\s+'), each.length]
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
