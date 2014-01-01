require 'yaml'
require 'erb'

include CiscoAclIntp
AclContainerBase.disable_color

############################################################

describe 'Scanner' do
  describe '#scan_line' do
    it 'should be parsed correct tokens as 1-line acl' do
      s = Scanner.new
      acl = <<'EOL'
ip access-list extended FA8-OUT
    deny   udp any any eq bootpc
    permit ip any any
EOL
      s.scan_line(acl).should == [
        [:NAMED_ACL, 'ip access-list'],
        ['extended', 'extended'],
        [:STRING, 'FA8-OUT'],
        [:EOS, nil],
        ['deny', 'deny'],
        ['udp', 'udp'],
        ['any', 'any'],
        ['any', 'any'],
        ['eq', 'eq'],
        ['bootpc', 'bootpc'],
        [:EOS, nil],
        ['permit', 'permit'],
        ['ip', 'ip'],
        ['any', 'any'],
        ['any', 'any'],
        [:EOS, nil],
        [:EOS, nil], # last, empty line
        [false, 'EOF']
     ]
    end
  end

end # describe Scanner

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
