# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_group 'Models', 'lib/'
end

require 'cisco_acl_intp'

include CiscoAclIntp
AclContainerBase.disable_color

RSpec::Matchers.define :be_aclstr do | expected_str |
  match do | actual_str |
    a = actual_str.strip
    b = expected_str.strip
    a.split(/\s+/) == b.split(/[\s\r\n]+/)
    ## by this method, whitespaces are skipped.
    ## because, it cannot handle correctly like 'remark foo  --  bar'
  end
end

# hash to hash-code-string
def _pph(hash)
  kv = []
  hash.each do | k, v |
    case v
    when String
      kv.push %(:#{k}=>"#{v}")
    else
      kv.push %(:#{k}=>#{v})
    end
  end
  kv.join(',')
end

# return specdir
def _spec_dir(file)
  specdir = Dir.new('./spec/cisco_acl_intp/')
  File.join(specdir.path, file)
end

# return test config/data dir
def _spec_conf_dir(file)
  specdir = Dir.new('./spec/conf/')
  File.join(specdir.path, file)
end

# return spec_data dir
def _spec_data_dir(file)
  datadir = Dir.new('./spec/data/')
  File.join(datadir.path, file)
end
