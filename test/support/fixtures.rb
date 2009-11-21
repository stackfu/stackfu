module Fixtures
  ApiUrlPrefix = StackFu::API.gsub(/api/, "flipper:abc123@api")

  def with_providers(kind=nil)
    register :get, :path => "providers", :kind => kind
  end
  
  def with_provider(id, kind=nil)
    register :get, :path => "providers/#{id}/#{kind}", :fixture => "providers", :kind => kind
  end
  
  def with_stacks(kind=nil, params=nil)
    register :get, :path => "stacks", :kind => kind, :params => params
  end
  
  def with_stack_add(kind=nil)
    register :post, :path => "stacks", :fixture => "stack_add", :kind => kind
  end
  
  def with_server_list(kind=nil, params=nil)
    register :get, :path => "servers", :kind => kind, :params => params
  end
  
  def with_server_add(kind=nil)
    register :post, :path => "servers", :fixture => "server_add", :kind => kind
  end

  def with_server_delete(kind=nil)
    register :delete, :path => "servers/4afe06b9e1054e1e00000002", :fixture => "server_add", :kind => kind
  end

  def with_user(id, kind=nil)
    register :get, :path => "users/#{id}/#{kind}", :fixture => "users", :kind => kind
  end

  def with_users(kind=nil)
    register :get, :path => "users", :kind => kind
  end

  def with_users_update(kind=nil)
    register :post, :path => "users", :fixture => "users_update", :kind => kind
  end
  
  def with_new_deployment(kind=nil)
    register :post, :path => "deployments", :fixture => "deployment_add", :kind => kind
  end

  private

  def register(method, options) # path, kind, fixture=path)
    kind = options[:kind] ? "_#{options[:kind]}" : ""
    path = options[:path] or raise "path is mandatory"
    fixture = options[:fixture] || options[:path]
    params = options[:params] ? "?#{options[:params]}" : ""
    
    # d "Registering: #{ApiUrlPrefix}/#{path}.json#{params} => #{fixture}#{kind}"
    FakeWeb.register_uri(method, "#{ApiUrlPrefix}/#{path}.json#{params}", 
      :response => fixture("#{fixture}#{kind}"))
  end
  
  def fixture(*path)
    File.join(File.dirname(__FILE__), "../fixtures", path)
  end

  def fixture_contents(*path)
    File.open(File.join(File.dirname(__FILE__), "../fixtures", path), "r").readlines.join("")
  end
end