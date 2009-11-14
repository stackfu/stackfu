module Fixtures
  ApiUrlPrefix = "https://api.stackfu.com"
  
  def with_server_list(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:get, "#{ApiUrlPrefix}/servers.json", :response => fixture("servers#{kind}"))
  end
  
  def with_server_add(kind=nil)
    kind = kind ? "_#{kind}" : ""
    FakeWeb.register_uri(:post, "#{ApiUrlPrefix}/servers.json", :response => fixture("server_add_#{kind}"))
  end

  private
  
  def fixture(*path)
    File.join(File.dirname(__FILE__), "../fixtures", path)
  end

  def fixture_contents(*path)
    File.open(File.join(File.dirname(__FILE__), "../fixtures", path), "r").readlines.join("")
  end
end