require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestConfigCommand < Test::Unit::TestCase
  should "Ask the login, token and offer to add a new server" do
    when_asked "StackFu Login: ", :answer => "flipper"
    when_asked "StackFu Token: ", :answer => "abc123"
  
    agree_with "Is this information correct? "
    
    ConfigCommand.any_instance.expects(:save_config).with("flipper", "abc123")
    command "config"
    stdout.should =~ /Configuration saved/
  end
  
  should "Ask the login, token again if information not correct" do
    when_asked "StackFu Login: ", :answer => "flipper"
    when_asked "StackFu Token: ", :answer => "abc123"

    disagree_of "Is this information correct? "

    when_asked "StackFu Login: ", :answer => "flipper"
    when_asked "StackFu Token: ", :answer => "abc123"

    agree_with "Is this information correct? "
    
    ConfigCommand.any_instance.expects(:save_config).with("flipper", "abc123")
    command "config" 
    stdout.should =~ /Configuration saved/
  end
end