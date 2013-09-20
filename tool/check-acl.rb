$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'optparse'
require 'CiscoAclIntp'

include CiscoAclIntp

opts = {}
OptionParser.new do | each |
  each.banner = "ruby #$0 [options] [args]"
  each.on( "-c", "--color", "enable coloring" ) do |x|
    opts[:color] = x
  end
  each.on( "-d", "--debug", "enable debug print" ) do |x|
    opts[:debug] = x
  end
  each.on( "--yydebug", "enable yydebug" ) do |x|
    opts[:yydebug] = x
  end
  each.on( "-f FILE", "--file", "acl file" ) do |x|
    opts[:file] = x
  end
  begin
    each.parse!
  rescue
    puts "invalid option."
    puts each
  end
end

acl_table = nil
popts = {}
popts[:color] = opts[:color] or false
popts[:debug] = opts[:debug] or false
popts[:yydebug] = opts[:yydebug] or false

parser = CiscoAclIntp::Parser.new( popts )

# read acl from file or STDIN
if opts[:file]
  parser.parse_file opts[:file]
else
  parser.parse_file $stdin
end

# print acl data
aclt = parser.acl_table
aclt.each do | name, acl |
  puts "acl name : #{name}"
  puts acl.to_s
end
