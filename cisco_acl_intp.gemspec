# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cisco_acl_intp/version'

Gem::Specification.new do |spec|
  spec.name          = 'cisco_acl_intp'
  spec.version       = CiscoAclIntp::VERSION
  spec.authors       = ['stereocat']
  spec.email         = ['stereocat@gmail.com']
  spec.description   = 'Cisco ACL Interpreter'
  spec.summary       = 'Cisco IOS Access Control List Interpreter'
  spec.homepage      = 'https://github.com/stereocat/cisco_acl_intp'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin\/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)\/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'netaddr', '~> 1.5.1'
  spec.add_runtime_dependency 'term-ansicolor', '~> 1.3.2'
  spec.add_development_dependency 'bundler', '~> 1.1l.2'
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
