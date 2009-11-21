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
  
  should "deploy the stack when it's found" do
    with_stacks("by_name", "stack%5Bname%5D=my_stack")
    command "deploy stack my_stack server"
  end
end