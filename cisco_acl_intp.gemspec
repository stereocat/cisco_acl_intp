# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cisco_acl_intp/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 2.5.0'
  spec.name          = 'cisco_acl_intp'
  spec.version       = CiscoAclIntp::VERSION
  spec.authors       = ['stereocat']
  spec.email         = ['stereocat@gmail.com']
  spec.description   = 'Cisco ACL Interpreter'
  spec.summary       = 'Cisco IOS Access Control List Interpreter'
  spec.homepage      = 'https://github.com/stereocat/cisco_acl_intp'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'netaddr', '~> 1.5.1'
  spec.add_runtime_dependency 'term-ansicolor', '~> 1.7.1'
  spec.add_development_dependency 'bundler', '~> 2.2.15'
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
