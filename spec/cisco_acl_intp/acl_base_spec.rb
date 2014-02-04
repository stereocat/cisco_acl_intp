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
          instance_eval("tag_#{tag.to_s}(@str)")
        end

        def to_s_with_cleaning
          clean_acl_string(' foo    bar baz    ')
        end
      end
      @mock = TestAclContainer.new('teststr')
    end

    it 'shoud be cleaning whitespace' do
      @mock.to_s_with_cleaning.should eq 'foo bar baz'
    end

    it 'should be same as raw string' do
      AclContainerBase.color_mode = :none
      @mock.to_s_with_tag(:port).should eq 'teststr'
    end

    it 'should be colored string when mode html' do
      AclContainerBase.color_mode = :html
      tag = :header
      matchstr = "span.*acltag_#{tag.to_s}.*teststr.*span"
      @mock.to_s_with_tag(tag).should match(/#{matchstr}/)
      AclContainerBase.color_mode = :none
    end

    it 'should be colored string when mode term' do
      AclContainerBase.color_mode = :term
      @mock.to_s_with_tag(:error).should match(/\e\[0?\d+m.*teststr.*\e\[0?m/)
      AclContainerBase.color_mode = :none
    end

    it 'should be raised NoMethodError when unknown tag' do
      lambda do
        @cntr.to_s_with_tag(:hoge)
      end.should raise_error(NoMethodError)
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
