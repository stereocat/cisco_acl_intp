# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'CiscoAclIntp'

RSpec::Matchers.define :be_aclstr do | expected_str |
  match do | actual_str |
    a = actual_str.strip
    b = expected_str.strip
    a.split(/\s+/) == b.split(/[\s\r\n]+/)
    ## この方法だと空白よみとばしてしまうので、
    ## 'remark foo  --  bar' みたいなのがただしく扱えない。
  end
end
