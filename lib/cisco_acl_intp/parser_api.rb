# frozen_string_literal: true

require 'forwardable'
require 'stringio'
require 'cisco_acl_intp/scanner'
require 'cisco_acl_intp/acl'

module CiscoAclIntp
  # ACL Parser Error Handler
  class ParserErrorHandler
    # Error count found in parsed file/string
    attr_reader :error_count
    # Error message list found in parsed file/string
    attr_reader :error_list

    # Constructor
    def initialize
      @error_count = 0
      @error_list = []
    end

    # Reset error count
    def reset_count
      @error_count = 0
    end

    # Count error
    def count
      @error_count += 1
    end

    # Regist error messages to list
    # @param [String] str Message string
    def regist_message(str)
      count
      @error_list.push(str)
    end

    # Parsed data contains error or not?
    # @return [Boolean]
    def contains_error?
      @error_count.positive?
    end
  end

  # ACL Parser Utilities
  module ParserUtility
    # Generate parser error message by Racc::ParseError
    # @param [Racc::ParseError] err Exception
    def racc_parse_err_message(err)
      [
        'Parse aborted. Found syntax error:',
        "  #{err.message}"
      ].join("\n")
    end

    # Generate parser error message by AclArgumentError
    # @param [AclArgumentError] err Exception
    # @param [String] pos_str Error position string
    def acl_arg_err_message(err, pos_str)
      [
        'Parse aborted. Found acl argment error:',
        "  #{err.message}",
        "  #{pos_str}"
      ].join("\n")
    end

    # Generate parser error message by AclError
    # @param [AclError] err Exception
    def acl_err_message(err)
      [
        'Parse aborted. Found acl error:',
        "  #{err.message}"
      ].join("\n")
    end

    # Generate parser error message by other exception
    # @param [StandardError] err Exception
    def err_message(err)
      [
        'Parse aborted. Found unknown error:',
        "  #{err.message}"
      ].join("\n")
    end
  end

  # ACL Parser
  class Parser < Racc::Parser
    include ParserUtility
    extend Forwardable

    # @return [Hash] ACL Table by ACL name key
    attr_reader :acl_table

    def_delegators :@err_handler, :contains_error?, :error_count, :error_list

    # Constructor
    # @param [Hash] opts Options
    # @option [Boolean] :yydebug Enable Racc debug print.
    #   (default: false)
    # @option [Boolean] :debug Enable debug print.
    #   (default: false)
    # @option [Symbol] :color Mode of token coloring
    #   (default: `:none`)
    # @option [Boolean] :silent Enable all parser syntax error
    #   (default: false)
    # @return [CiscoACLParser]
    def initialize(opts)
      super()
      @yydebug = opts[:yydebug] || false
      @debug_print = opts[:debug] || false
      @silent_mode = @debug_print || opts[:silent] || false

      @color_mode = opts[:color] || :none
      AccessControlContainer.color_mode = @color_mode

      @err_handler = ParserErrorHandler.new
      @err_handler.reset_count

      @acl_table = {}
      @curr_acl_name = ''
      @line_number = 0
    end

    # Scan/Parse ACL from file
    # @param [String] filename File name
    # @raise [AclError]
    # @return [Hash] ACL Table
    def parse_file(filename)
      run_parser do
        case filename
        when String
          File.new(filename)
        when IO, StringIO
          filename
        else
          @err_handler.count
          raise AclError, "File: #{filename} not found."
        end
      end
    end

    # Scan/Parse ACL from string
    # @param [String] acl_str ACL string
    # @raise [AclError]
    # @return [Hash] ACL Table
    def parse_string(acl_str)
      run_parser do
        case acl_str
        when String
          StringIO.new(acl_str)
        when IO, StringIO
          acl_str
        else
          @err_handler.count
          raise AclError, "Argument: #{acl_str} not found."
        end
      end
    end

    # Syntax error handler
    def on_error(tok, val, _vstack)
      err_str = format(
        '%<ep>s, near value: %<val>s, (token: %<token>s)',
        ep: err_pos_str, val: val, token: token_to_str(tok)
      )
      @err_handler.regist_message(err_str)
    end

    # ACL table handling
    # @param [String] acl_name ACL Name
    # @param [AceBase] acl_entry ACL Object
    # @param [Class] acl_class ACL Class
    def add_acl_table_with_acl(acl_name, acl_entry, acl_class)
      @curr_acl_name = acl_name
      unless @acl_table.key?(acl_name)
        @acl_table[acl_name] = acl_class.new(acl_name)
        @line_number = 0
      end
      @acl_table[acl_name].add_entry(acl_entry)
      @line_number += 1
    end

    private

    # Run parser and Handle its Error(exception)
    # @yield Pre-process of running parser
    # @yieldreturn [IO] IO object of file/string
    # @return [Hash] ACL Table
    def run_parser
      begin
        # reset error count
        @err_handler.reset_count
        # do scan/parse
        scanner = Scanner.new
        @queue = scanner.scan_file(yield)
        do_parse
      rescue Racc::ParseError => e
        @err_handler.regist_message(racc_parse_err_message(e))
      rescue AclArgumentError => e
        @err_handler.regist_message(acl_arg_err_message(e, err_pos_str))
      rescue AclError => e
        @err_handler.regist_message(acl_err_message(e))
      rescue StandardError => e
        @err_handler.regist_message(err_message(e))
      end
      @acl_table
    end

    # print error message and enter error recovery mode
    # @param [String] str Error message
    def yyerror_with(str)
      @err_handler.regist_message "#{err_pos_str}, #{str}"
      yyerror
    end

    # debug print
    # @param [String] str String to print
    def dputs(str)
      puts "[debug] #{str}" if @debug_print
    end

    # Get next token
    # @return [Array] Next token array
    def next_token
      @queue.shift
    end

    # Generate error string
    # @return [String] error position string
    def err_pos_str
      format(
        'in acl: %<acl>s, line: %<line>s',
        acl: @curr_acl_name,
        line: @acl_table.key?(@curr_acl_name) ? @acl_table[@curr_acl_name].length + 1 : ''
      )
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
