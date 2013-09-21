# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cisco_acl_intp/version'

Gem::Specification.new do |spec|
  spec.name          = "cisco_acl_intp"
  spec.version       = CiscoAclIntp::VERSION
  spec.authors       = ["stereocat"]
  spec.email         = ["stereocat@gmail.com"]
  spec.description   = %q{Cisco Access List Interpreter}
  spec.summary       = %q{Cisco Access List Interpreter}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
