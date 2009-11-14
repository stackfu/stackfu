require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestServerCommand < Test::Unit::TestCase
  should "map 'server' to ServerCommand" do
    Command.create("server").class.should == ServerCommand
  end
  
  should "indicate user have no servers" do
    with_server_list "empty"
    command "server list"
    stdout.should == "You have no servers under your account. Try adding some with 'server add' command.\n"
  end

  context "adding a slicehost server" do
    should "ask for credentials when none were given before" do
      # stackfu server add slicehost slicey
      with_server_add "success"

      agree_with "Do you want to add your credentials now?"
      when_asked "Enter your Slicehost API password (or type 'help' for more information or 'abort' to abort):\n", 
        :answer => "abc123"
        
      command "server add slicehost slicey"
    end
  end
  
  # should "return a list of all servers when no argument is given" do
  #   stub_authentication
  #   stub_servers
  #   
  #   cmd = ServerCommand.new
  #   cmd.run
  #   
  #   last_command_output.should include("slicey")
  #   last_command_output.should include("174.102.93.16")
  # end
end