require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/clean"

LIB_DIR = "./lib"
ACL_SPEC_TESTDATA_DIR = "./spec/data"
CLASS_DIR = "#{ LIB_DIR }/CiscoAclIntp"
CLASS_GRAPH_DOT = "doc/CiscoAclIntp.dot"
CLASS_GRAPH_PNG = "doc/CiscoAclIntp.png"
PARSER_RACC = "#{ CLASS_DIR }/parser.ry"
PARSER_RUBY = "#{ CLASS_DIR }/parser.rb"

CLEAN.include(
  "#{ ACL_SPEC_TESTDATA_DIR }/*.acl.yml",
  "#{ ACL_SPEC_TESTDATA_DIR }/*.token.yml",
  "#{ LIB_DIR }/*.output",
)
CLOBBER.include(
  PARSER_RUBY,
  CLASS_GRAPH_DOT,
  CLASS_GRAPH_PNG
)

task :default => [ :parser, :spec ]
task :parser => [ PARSER_RUBY ]
task :spec => [ ACL_SPEC_TESTDATA_DIR ]

task :doc do
  sh "yard doc #{ LIB_DIR }/*/*.rb"
  sh "yard graph --full -f #{CLASS_GRAPH_DOT}"
  sh "dot -Tpng #{CLASS_GRAPH_DOT} -o #{CLASS_GRAPH_PNG}"
end

directory ACL_SPEC_TESTDATA_DIR

file PARSER_RUBY => [ PARSER_RACC ] do
  sh "racc -v -g #{ PARSER_RACC } -o #{ PARSER_RUBY }"
end

RSpec::Core::RakeTask.new( :spec ) do | spec |
  spec.pattern = FileList[ "spec/**/*_spec.rb" ]
  spec.rspec_opts = "--format documentation --color"
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
