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
    
    when_asked "   Nome: ", :answer => "Felipe"
    when_asked "  Idade: ", :answer => "31"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey"
    
    stdout.should =~ /Deploying:/
    stdout.should =~ /Ubuntu 8.10/
    stdout.should =~ /my_stack/
    stdout.should =~ /This will deploy my stack/
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
    
    command "deploy stack my_stack slicey"
    stdout.should =~ /Deploying:/
  end
  
  should "submit the deployment asking only for parameters not provided" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment
    
    when_asked "  Idade: ", :answer => "31"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey --nome=Felipe"
    
    stdout.should =~ /Deploying:/
    stdout.should =~ /Ubuntu 8.10/
    stdout.should =~ /my_stack/
    stdout.should =~ /This will deploy my stack/
  end

  should "submit the deployment using options should validate values" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment

    when_asked "   Nome: ", :answer => "Felipe"
    when_asked "  Idade: ", :answer => "31"
    
    agree_with "This will destroy current contents of your server. Are you sure?\n"
    
    command "deploy stack my_stack slicey --idade=Abc"
    
    stdout.should =~ /Value for idade should be numeric/
  end
end