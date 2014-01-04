require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rake/clean'

LIB_DIR = './lib'
PACKAGE_NAME = 'cisco_acl_intp'
SPEC_ORIG_DIR = 'spec'
SPEC_DIR = "#{SPEC_ORIG_DIR}/#{PACKAGE_NAME}/"
SPEC_DATA_DIR = "#{SPEC_ORIG_DIR}/data"
CLASS_DIR = "#{LIB_DIR}/#{PACKAGE_NAME}"
CLASS_GRAPH_DOT = "doc/#{PACKAGE_NAME}.dot"
CLASS_GRAPH_PNG = "doc/#{PACKAGE_NAME}.png"
PARSER_RACC = "#{CLASS_DIR}/parser.ry"
PARSER_RUBY = "#{CLASS_DIR}/parser.rb"

CLEAN.include(
  "#{SPEC_DATA_DIR}/*.*",
  "#{LIB_DIR}/*.output"
)
CLOBBER.include(
  PARSER_RUBY,
  CLASS_GRAPH_DOT,
  CLASS_GRAPH_PNG
)

task default: [:parser, :spec]
task parser: [PARSER_RUBY]
task spec: [SPEC_DATA_DIR]

task :fullfill do
  # generate full-fill pattern test scripts
  sh "ruby #{SPEC_ORIG_DIR}/parser-fullfill-patterns.rb"
end

directory SPEC_DATA_DIR
file PARSER_RUBY => [PARSER_RACC] do
  sh "racc -v -g #{PARSER_RACC} -o #{PARSER_RUBY}"
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList["#{SPEC_DIR}/*_spec.rb"]
  spec.rspec_opts = '--format documentation --color'
end

RSpec::Core::RakeTask.new(fullspec: [:fullfill]) do |spec|
  spec.pattern = FileList["#{SPEC_ORIG_DIR}/**/*_spec.rb"]
  spec.rspec_opts = '--format documentation --color'
end

# documentation by yard
require 'yard'
require 'yard/rake/yardoc_task'
YARD::Rake::YardocTask.new do |task|
  task.files = ["#{LIB_DIR}/**/*.rb"]
  task.options = %w['--protected' '--private']
end

task :docgraph do
  # need to install graphviz package
  sh "yard graph --full -f #{CLASS_GRAPH_DOT}"
  sh "dot -Tpng #{CLASS_GRAPH_DOT} -o #{CLASS_GRAPH_PNG}"
end

# rubocop settings
if RUBY_VERSION >= '1.9.0'
  task quality: :rubocop
  require 'rubocop/rake_task'
  Rubocop::RakeTask.new do |task|
    # file patterns in ".rubocop.yml"
    task.fail_on_error = false
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
