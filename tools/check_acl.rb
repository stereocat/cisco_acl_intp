# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'optparse'
require 'cisco_acl_intp'

opts = {}
OptionParser.new do | each |
  each.banner = "ruby #{$PROGRAM_NAME} [options] [args]"
  each.on('-c MODE', '--color', 'enable coloring (MODE=[term, html]') do |x|
    opts[:color] = x.intern
  end
  each.on('-d', '--debug', 'enable debug print') do |x|
    opts[:debug] = x
  end
  each.on('--yydebug', 'enable yydebug') do |x|
    opts[:yydebug] = x
  end
  each.on('-f FILE', '--file', 'acl file') do |x|
    opts[:file] = x
  end
  begin
    each.parse!
  rescue
    puts 'invalid option.'
    puts each
  end
end

popts = {}
popts[:color] = opts[:color] || :none
popts[:debug] = opts[:debug] || false
popts[:yydebug] = opts[:yydebug] || false

parser = CiscoAclIntp::Parser.new(popts)

# read acl from file or STDIN
if opts[:file]
  parser.parse_file opts[:file]
else
  parser.parse_file $stdin
end

# print error message in acl
error_list = parser.error_list
unless error_list.empty?
  puts '--------------------'
  error_list.each do |each|
    puts each.to_s
  end
  puts '--------------------'
end

# print acl data
acl_table = parser.acl_table
acl_table.each do |name, acl|
  puts "acl name : #{name}"
  puts acl.to_s
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
