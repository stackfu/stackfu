require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestConfigCommand < Test::Unit::TestCase
  context "provider command" do
    should "recognize Webbynode" do
      with_users
      with_users_update("4afe06b8e1054e1e00000001")
      
      when_asked "Webbynode Login:", :answer => "fcoury@me.com"
      when_asked "Webbynode Token:", :answer => "abc123"
      
      command "config webbynode"
      stdout.should =~ /Webbynode credentials saved./
    end

    should "recognize Webbynode" do
      with_users
      with_users_update("4afe06b8e1054e1e00000001")
      
      when_asked "Webbynode Login:", :answer => "fcoury@me.com"
      when_asked "Webbynode Token:", :answer => "abc123"
      
      command "config webbynode"
      stdout.should =~ /Webbynode credentials saved./
    end

    should "recognize Slicehost" do
      with_users
      with_users_update("4afe06b8e1054e1e00000001")
      
      when_asked "", :answer => "6ed05e7521dfb6a19c98a84f2d0a28fdffc1bf00e050fe7114a66d3049e9715e"
      
      command "config slicehost"
      stdout.should =~ /Slicehost credentials saved./
    end
  end
  
  context "default command" do
    should "skip asking login, token and confirmation if --login and --token provided" do
      ConfigCommand.any_instance.expects(:save_config).with("flipper", "abc123")
      command "config --login=flipper --token=abc123"
      stdout.should =~ /Configuration saved/
    end

    should "skip asking login if --login provided" do
      when_asked "StackFu Token: ", :answer => "abc123"

      agree_with "Is this information correct? "

      ConfigCommand.any_instance.expects(:save_config).with("flipper", "abc123")
      command "config --login=flipper"
      stdout.should =~ /Configuration saved/
    end

    should "skip asking token if --token provided" do
      when_asked "StackFu Login: ", :answer => "flipper"

      agree_with "Is this information correct? "

      ConfigCommand.any_instance.expects(:save_config).with("flipper", "abc123")
      command "config --token=abc123"
      stdout.should =~ /Configuration saved/
    end

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
end