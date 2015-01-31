# -*- coding: utf-8 -*-
require 'spec_helper'
require 'yaml'

describe 'Scanner' do
  describe '#scan_line' do
    before(:all) do
      @s = Scanner.new
    end

    it 'should be parsed correct tokens as 1-line acl' do
      acl = <<'EOL'
ip access-list extended FA8-OUT
    deny   udp any any eq bootpc
    permit ip any any
EOL
      expect(@s.scan_line(acl)).to eq(
        [
          [:NAMED_ACL, 'ip access-list'],
          %w(extended extended),
          [:STRING, 'FA8-OUT'],
          [:EOS, nil],
          %w(deny deny),
          %w(udp udp),
          %w(any any),
          %w(any any),
          %w(eq eq),
          %w(bootpc bootpc),
          [:EOS, nil],
          %w(permit permit),
          %w(ip ip),
          %w(any any),
          %w(any any),
          [:EOS, nil],
          [false, 'EOF']
        ])
    end

    tokens = YAML.load_file(_spec_conf_dir('single_tokens.yml'))
    tokens.each do |each|
      # run test
      it "should be parsed single token: #{each}" do
        expect(@s.scan_line(each)).to eq [
          [each, each],
          [:EOS, nil],
          [false, 'EOF']
        ]
      end
    end
  end # scan_line

  describe '#scan_file' do
    before do
      @s = Scanner.new
    end

    tests = YAML.load_file(_spec_conf_dir('scanner_spec_data.yml'))

    # generate test data (yaml file)
    tests.each do |each_test|
      tokens = []
      lines = each_test[:test_data]

      # filename
      acl_file_base = [each_test[:test_symbol], '.acl.yml'].join
      acl_file = _spec_data_dir(acl_file_base)

      # generate access list string data file
      # (input for scanner)
      File.open(acl_file, 'w') do |file|
        lines.each do |each_line|
          file.puts each_line[:line]

          next unless each_line[:tokens]
          # make tokens data
          each_line[:tokens].each do |each_token|
            case each_token
            when Array
              (symbstr, val) = each_token
              tokens.push [symbstr.intern, val] # symbolize
            when String
              tokens.push [each_token, each_token]
            end
          end
          tokens.push [:EOS, nil] # End of String
        end
        tokens.push [false, 'EOF'] # last token (End of File)
      end

      # filename
      token_file_base = [each_test[:test_symbol], '.token.yml'].join
      token_file = _spec_data_dir(token_file_base)

      # generate access list token data file
      # (expected output of scanner)
      File.open(token_file, 'w') do |file|
        YAML.dump(tokens, file)
      end

      # run test
      it "should be parsed #{File.basename(acl_file)} as \
#{File.basename(token_file)} in tests of \
#{each_test[:test_description]}" do
        tokens = YAML.load_file(token_file)
        File.open(acl_file) do |file|
          expect(@s.scan_file(file)).to eq tokens
        end
      end
    end # tests.each
  end # scan_file
end # describe Scanner

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
