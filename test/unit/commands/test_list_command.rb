require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestListCommand < Test::Unit::TestCase
  should "map 'list' to ServerCommand" do
    Command.create("list").class.should == ListCommand
  end
  
  should "tell the user if no stack found" do
    with_users
    with_stacks("empty")
    command "list"
    stdout.should =~ /You have nothing to list yet. To generate stacks or plugins, try the 'stackfu generate' command/
  end
  
  should "list 1 stack" do
    with_users
    with_stacks
    command "list"
    stdout.should =~ /Listing 1 stack/
    stdout.should =~ /type/
    stdout.should =~ /name/
    stdout.should =~ /my_stack/
  end
  
  should "list 2 stacks" do
    with_users
    with_stacks("multiple")
    command "list"
    stdout.should =~ /Listing 2 stacks/
    stdout.should =~ /type/
    stdout.should =~ /name/
    stdout.should =~ /my_stack/
    stdout.should =~ /another_stack/
  end
end