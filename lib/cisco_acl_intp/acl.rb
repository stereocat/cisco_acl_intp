# -*- coding: utf-8 -*-

require 'forwardable'
require 'cisco_acl_intp/acl_category_base'

module CiscoAclIntp
  # Named extended ACL container
  class NamedExtAcl < NamedAcl
    include ExtAcl

    # Constructor
    # @param [String] name ACL name
    # @return [NamedExtAcl]
    def initialize(name)
      super
      @name_type = :named
      @acl_type = :extended
    end
  end

  # Numbered extended ACL container
  class NumberedExtAcl < NumberedAcl
    include ExtAcl

    # Constructor
    # @param [String, Integer] name ACL name
    # @return [NumberedExtAcl]
    def initialize(name)
      super
      @name_type = :numbered
      @acl_type = :extended
    end
  end

  # Named standard ACL container
  class NamedStdAcl < NamedAcl
    include StdAcl

    # Constructor
    # @param [String] name ACL name
    # @return [NamedStdAcl]
    def initialize(name)
      super
      @name_type = :named
      @acl_type = :standard
    end
  end

  # Numbered standard ACL container
  class NumberedStdAcl < NumberedAcl
    include StdAcl

    # Constructor
    # @param [String, Integer] name ACL name
    # @return [NumberedStdAcl]
    def initialize(name)
      super
      @name_type = :numbered
      @acl_type = :standard
    end
  end
end # module

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
