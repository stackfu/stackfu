module Fixtures
  ApiUrlPrefix = StackFu::API.gsub(/api/, "flipper:abc123@api")

  def with_providers(kind=nil)
    register :get, "providers", kind
  end
  
  def with_provider(id, kind=nil)
    register :get, "providers/#{id}/#{kind}", kind, "providers"
  end
  
  def with_stacks(kind=nil)
    register :get, "stacks", kind
  end
  
  def with_stack_add(kind=nil)
    register :post, "stacks", kind, "stack_add"
  end
  
  def with_server_list(kind=nil)
    register :get, "servers", kind
  end
  
  def with_server_add(kind=nil)
    register :post, "servers", kind, "server_add"
  end

  def with_server_delete(kind=nil)
    register :delete, "servers/4afe06b9e1054e1e00000002", kind, "server_add"
  end

  def with_user(id, kind=nil)
    register :get, "users/#{id}/#{kind}", kind, "users"
  end

  def with_users(kind=nil)
    register :get, "users", kind
  end

  def with_users_update(kind=nil)
    register :post, "users", kind, "users_update"
  end

  private

  def register(method, path, kind, fixture=path)
    kind = kind ? "_#{kind}" : ""
    # d "Registering: #{ApiUrlPrefix}/#{path}.json => #{fixture}#{kind}"
    FakeWeb.register_uri(method, "#{ApiUrlPrefix}/#{path}.json", :response => fixture("#{fixture}#{kind}"))
  end
  
  def fixture(*path)
    File.join(File.dirname(__FILE__), "../fixtures", path)
  end

  def fixture_contents(*path)
    File.open(File.join(File.dirname(__FILE__), "../fixtures", path), "r").readlines.join("")
  end
end