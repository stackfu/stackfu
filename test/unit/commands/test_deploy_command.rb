require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestDeployCommand < Test::Unit::TestCase
  should "map 'deploy' to DeployCommand" do
    Command.create("deploy").class.should == DeployCommand
  end
  
  should "present the options when none given" do
    command "deploy"
    stdout.should =~ /You have to tell what you want to deploy \(a stack or a plugin\) and to which server/
  end
  
  should "show an error when the stack is not found" do
    with_stacks("empty", "stack%5Bname%5D=my_stack")
    command "deploy stack my_stack server"
    stdout.should =~ /Stack 'my_stack' was not found/
  end
  
  should "show an error when server not found" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("empty", "server%5Bhostname%5D=slicey")
    command "deploy stack my_stack slicey"
    stdout.should =~ /Server 'slicey' was not found/
  end

  should "tell the user if there's a problem submitting the deployment" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment("error")
    
    when_asked "   Nome: ", :answer => "Felipe"
    when_asked "  Idade: ", :answer => "31"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey"
    stdout.should =~ /There was a problem submitting your deployment: This is an error/
  end

  should "submit the deployment when stack and server exists" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment

    uri = StackFu::API.gsub(/api/, "flipper:abc123@api")
    FakeWeb.register_uri(:get, "#{uri}/deployments/4b0b3421e1054e3102000001.json", 
      :response => fixture("deployments"))

    FakeWeb.register_uri(:get, "#{uri}/deployments/4b0b3421e1054e3102000001/logs.json?formatted=true&from=", 
      :response => fixture("logs"))

    FakeWeb.register_uri(:get, "#{uri}/deployments/4b0b3421e1054e3102000001/logs.json?formatted=true", 
      :response => fixture("logs"))

    FakeWeb.register_uri(:get,
      "#{uri}/deployments/4b0b3421e1054e3102000001/logs.json?formatted=true&from=4b0b34c9e1054e3104000109", 
      :response => fixture("logs_partial"))
      
    require 'net/http'
    require 'uri'
    
    Net::HTTP.start('api.stackfu.com') {|http|
      req = Net::HTTP::Get.new('/deployments/4b0b3421e1054e3102000001/logs.json?formatted=true')
      req.basic_auth 'flipper', 'abc123'
      response = http.request(req)
      # ppd JSON.load(response.body)
    }
    
    Net::HTTP.start('api.stackfu.com') {|http|
      req = Net::HTTP::Get.new('/deployments/4b0b3421e1054e3102000001/logs.json?formatted=true&from=4b0b34c9e1054e3104000109')
      req.basic_auth 'flipper', 'abc123'
      response = http.request(req)
      # d response.body
      # d JSON.load(response.body)["id"]
      # d JSON.load(response.body)["log"]
    }
    
    when_asked "   Nome: ", :answer => "Felipe"
    when_asked "  Idade: ", :answer => "31"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey"
    
    stdout.should =~ /Deploying:/
    stdout.should =~ /Ubuntu 8.10/
    stdout.should =~ /my_stack/
    stdout.should =~ /This will deploy my stack/
    stdout.should =~ /Enqueued for execution \(deployment id 4b0b3421e1054e3102000001 at Tue Nov 24 01:17:25 UTC 2009\)/
    stdout.should_not =~ /Please review the configuration for your deployment:/
  end
  
  should "pass the params" do
    stack = mock("stack")
    stack.expects(:name).returns("my_stack")
    stack.expects(:operating_system).returns("ubuntu_810")
    stack.expects(:description).returns("My stack description")

    control = mock("control")
    control.expects(:label).at_least_once.returns("Nome")
    control.expects(:name).at_least_once.returns("name")
    control.expects(:_type).at_least_once.returns("Textbox")
    stack.expects(:controls).at_least_once.returns([control])

    ApiHooks::Stack.expects(:find).returns([stack])
    
    server = mock("server")
    ApiHooks::Server.expects(:find).returns([server])
    
    deployment = mock("deployment")
    deployment.expects(:save).returns(true)
    
    ApiHooks::Deployment.expects(:new).with(:stack => stack, :server => server, :params => {"name" => "Felipe"}).returns(deployment)

    when_asked "  Nome: ", :answer => "Felipe"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey --no-follow"
    stdout.should =~ /Deploying:/
  end
  
  should "not tell the user to enter values if they are all provided" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey --nome=Felipe --idade=31 --no-follow"
    
    stdout.should =~ /Deploying:/
    stdout.should =~ /Ubuntu 8.10/
    stdout.should =~ /my_stack/
    stdout.should =~ /This will deploy my stack/
    stdout.should_not =~ /Please configure your deployment by answering the configuration settings below./
    stdout.should =~ /Please review the configuration for your deployment:/
    stdout.should =~ /Nome/
    stdout.should =~ /Felipe/
    stdout.should =~ /Idade/
    stdout.should =~ /31/
  end
  
  should "submit the deployment asking only for parameters not provided" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment
    
    when_asked "  Idade: ", :answer => "31"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey --nome=Felipe --no-follow"
    
    stdout.should =~ /Deploying:/
    stdout.should =~ /Ubuntu 8.10/
    stdout.should =~ /my_stack/
    stdout.should =~ /This will deploy my stack/
    stdout.should =~ /Please review the configuration for your deployment:/
    stdout.should =~ /Nome/
    stdout.should =~ /Felipe/
    stdout.should =~ /Idade/
    stdout.should =~ /31/
  end

  should "submit the deployment using options should validate values" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment

    when_asked "   Nome: ", :answer => "Felipe"
    when_asked "  Idade: ", :answer => "31"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey --idade=Abc --no-follow"
    
    stdout.should =~ /Value for idade should be numeric/
    stdout.should_not =~ /Please review the configuration for your deployment:/
  end
end