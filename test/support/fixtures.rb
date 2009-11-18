module Fixtures
  ApiUrlPrefix = StackFu::API.gsub(/api/, "flipper:abc123@api")
  
  def with_stacks(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:get, "#{ApiUrlPrefix}/stacks.json", :response => fixture("stacks#{kind}"))
  end
  
  def with_stack_add(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:post, "#{ApiUrlPrefix}/stacks.json", :response => fixture("stack_add#{kind}"))
  end
  
  def with_server_list(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:get, "#{ApiUrlPrefix}/servers.json", :response => fixture("servers#{kind}"))
  end
  
  def with_server_add(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:post, "#{ApiUrlPrefix}/servers.json", :response => fixture("server_add#{kind}"))
  end

  def with_server_delete(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:delete, "#{ApiUrlPrefix}/servers/4afe06b9e1054e1e00000002.json", :response => fixture("server_add#{kind}"))
  end

  def with_users(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:get, "#{ApiUrlPrefix}/users.json", :response => fixture("users#{kind}"))
  end

  def with_users_update(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:post, "#{ApiUrlPrefix}/users.json", :response => fixture("users_update#{kind}"))
  end

  private
  
  def fixture(*path)
    File.join(File.dirname(__FILE__), "../fixtures", path)
  end

  def fixture_contents(*path)
    File.open(File.join(File.dirname(__FILE__), "../fixtures", path), "r").readlines.join("")
  end
end