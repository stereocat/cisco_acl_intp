# -*- coding: utf-8 -*-

require 'spec_helper'

describe 'AclContainerBase' do
  describe '#generate_tagged_str' do
    before do
      # test mock
      class TestAclContainer < AclContainerBase
        def initialize(str)
          @str = str
        end

        def to_s_with_tag(tag)
          instance_eval("tag_#{tag}(@str)")
        end

        def to_s_with_cleaning
          clean_acl_string(' foo    bar baz    ')
        end
      end
      @mock = TestAclContainer.new('teststr')
    end

    it 'shoud be cleaning whitespace' do
      expect(@mock.to_s_with_cleaning).to eq 'foo bar baz'
    end

    it 'should be same as raw string' do
      AclContainerBase.color_mode = :none
      expect(@mock.to_s_with_tag(:port)).to eq 'teststr'
    end

    it 'should be colored string when mode html' do
      AclContainerBase.color_mode = :html
      tag = :header
      matchstr = "span.*acltag_#{tag}.*teststr.*span"
      expect(@mock.to_s_with_tag(tag)).to match(/#{matchstr}/)
      AclContainerBase.color_mode = :none
    end

    it 'should be colored string when mode term' do
      AclContainerBase.color_mode = :term
      expect(@mock.to_s_with_tag(:error)).to match(
        /\e\[0?\d+m.*teststr.*\e\[0?m/
      )
      AclContainerBase.color_mode = :none
    end

    it 'should be raised NoMethodError when unknown tag' do
      expect do
        @cntr.to_s_with_tag(:hoge)
      end.to raise_error(NoMethodError)
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
