# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_group 'Models', 'lib/'
end

require 'cisco_acl_intp'

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
      kv.push %Q{:#{k.to_s}=>"#{v.to_s}"}
    else
      kv.push %Q{:#{k.to_s}=>#{v.to_s}}
    end
  end
  kv.join(',')
end
