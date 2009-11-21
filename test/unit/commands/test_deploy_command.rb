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

  should "submit the deployment when stack and server exists" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment
    command "deploy stack my_stack slicey"
    stdout.should =~ /Your deployment have been submitted/
  end

  should "tell the user if there's a problem submitting the deployment" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    with_server_list("by_name", "server%5Bhostname%5D=slicey")
    with_new_deployment("error")
    command "deploy stack my_stack slicey"
    stdout.should =~ /There was a problem submitting your deployment: This is an error/
  end
end