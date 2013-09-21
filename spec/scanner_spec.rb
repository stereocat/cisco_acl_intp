require 'yaml'

include CiscoAclIntp
AclContainerBase::disable_color

############################################################

describe "Scanner" do
  describe '#scan_line' do
    it "should be parsed correct tokens as 1-line acl" do
      s = Scanner.new
      acl = <<"END"
ip access-list extended FA8-OUT
    deny   udp any any eq bootpc
    permit ip any any
END
      s.scan_line( acl ).should == [
        [:NAMED_ACL, "ip access-list"],
        [:EXTENDED, "extended"],
        [:STRING, "FA8-OUT"],
        [:EOS, nil],
        [:DENY, "deny"],
        [:UDP, "udp"],
        [:ANY, "any"],
        [:ANY, "any"],
        [:EQ, "eq"],
        [:BOOTPC, "bootpc"],
        [:EOS, nil],
        [:PERMIT, "permit"],
        [:IP, "ip"],
        [:ANY, "any"],
        [:ANY, "any"],
        [:EOS, nil],
        [:EOS, nil], # last, empty line
        [false, "EOF"]
      ]
    end
  end

############################################################

specdir = Dir.new("./spec/")
datadir = Dir.new("./spec/data/")

codes = []
## generates test header
codes.push <<"EOS"
  describe '#scan_file' do
EOS

tests = YAML.load_file( File.join(specdir.path, 'scanner_spec_data.yml'))

# generate test data (yaml file)
tests.each do | each_test |
  tokens = []
  lines = each_test[ "test-data" ]

  # filename
  acl_file_base = [ each_test[ "test-symbol" ], ".acl.yml" ].join
  acl_file = File.join( datadir.path, acl_file_base )

  # generate access list string data file
  # (input for scanner)
  File.open( acl_file, "w" ) do | file |
    lines.each do | each_line |
      file.puts each_line[ "line" ]

      # make tokens data
      if each_line[ "tokens" ]
        each_line[ "tokens" ].each do | each_token |
          (symbol, value) = each_token
          tokens.push [ symbol.intern, value ] # symbolize
        end
        tokens.push [ :EOS, nil ] # End of String
      end
    end
    tokens.push [ false, 'EOF' ] # last token (End of File)
  end

  # filename
  token_file_base = [ each_test["test-symbol"], ".token.yml" ].join
  token_file = File.join( datadir.path, token_file_base )

  # generate access list token data file
  # (expected output of scanner)
  File.open(token_file, "w") do | file |
    YAML.dump( tokens, file )
  end

  ## generate test codes
  codes.push <<"EOS"
    it "should be parsed #{ File.basename(acl_file) } as #{ File.basename(token_file) } in tests of #{ each_test["test-description"] }" do
      tokens = YAML.load_file("#{ token_file }")
      s = Scanner.new
      File.open("#{ acl_file }") do | file |
        s.scan_file( file ).should == tokens
      end
    end
EOS
end # test.each

## generate test footer
codes.push <<"EOS"
  end # describe
EOS

eval codes.join

end # describe "Scanner"

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
