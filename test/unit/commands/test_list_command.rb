require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestListCommand < Test::Unit::TestCase
  should "map 'list' to ServerCommand" do
    Command.create("list").class.should == ListCommand
  end
  
  should "tell the user if no stack found" do
    with_users
    with_stacks("empty")
    with_plugins("empty")
    command "list"
    stdout.should =~ /You have nothing to list yet. To generate stacks or plugins, try the 'stackfu generate' command/
  end
  
  should "list 1 stack" do
    with_users
    with_stacks
    with_plugins("empty")
    command "list"
    stdout.should =~ /Listing 1 stack/
    stdout.should =~ /Type/
    stdout.should =~ /Name/
    stdout.should =~ /my_stack/
  end
  
  should "list 1 plugin" do
    with_users
    with_stacks("empty")
    with_plugins
    command "list"
    stdout.should =~ /Listing 1 plugin/
    stdout.should =~ /Type/
    stdout.should =~ /plugin/
    stdout.should =~ /Name/
    stdout.should =~ /my_plugin/
  end
  
  should "list 1 plugin and 2 stacks" do
    with_users
    with_stacks("multiple")
    with_plugins
    command "list --plain"
    stdout.should =~ /Listing 2 stacks and 1 plugin/
    stdout.should =~ /Type/
    stdout.should =~ /plugin/
    stdout.should =~ /Name/
    stdout.should =~ /my_plugin      plugin/
    stdout.should =~ /my_stack/
  end
  
  should "list 2 stacks" do
    with_users
    with_stacks("multiple")
    with_plugins("empty")
    command "list"
    stdout.should =~ /Listing 2 stacks/
    stdout.should =~ /Type/
    stdout.should =~ /Name/
    stdout.should =~ /my_stack/
    stdout.should =~ /another_stack/
  end
end