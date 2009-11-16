require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestServerCommand < Test::Unit::TestCase
  should "map 'server' to ServerCommand" do
    Command.create("server").class.should == ServerCommand
  end
  
  should "indicate user have no servers" do
    with_server_list "empty"
    command "server list"
    stdout.should =~ /You have no servers under your account. Try adding some with 'server add' command.\n/
  end
  
  context "add command" do
    should "require two parameters" do
      command "server add"
      stdout.should =~ /requires 2 parameters/
    end
  end
  
  context "adding a slicehost server" do
    should "abort when user says no to agreement" do
      with_users "no_credentials"

      disagree_of "Do you want to add your credentials now?"
      command "server add slicehost slicey"
      
      stdout.should =~ /Aborted/
      stdout.should_not =~ /Enter your Slicehost API password/
    end
    
    should "ask for credentials when none were given before" do
      # stackfu server add slicehost slicey
      with_users "no_credentials"
      with_users_update
      with_server_add

      agree_with "Do you want to add your credentials now?"
      when_asked "Enter your Slicehost API password (or type 'help' for more information or 'abort' to abort):\n", :answer => "abc123"
        
      command "server add slicehost slicey"
      stdout.should =~ /Server slicey added successfully/
    end

    should "add the server if proper credentials given" do
      # stackfu server add slicehost slicey
      with_users
      with_users_update
      with_server_add

      command "server add slicehost slicey"
      stdout.should =~ /Server slicey added successfully/
    end
    
    should "delete the server if proper credentials given and server exists" do
      with_users
      with_server_list
      with_server_delete
      
      command "server delete slicey"
      stdout.should =~ /Server slicey deleted successfully/
    end
    
    should "show a selection when same server hostname repeats in more than one provider"
    
    should "show the slicehost server when listing servers" do
      with_users
      with_server_list
      
      command "server"
      stdout.should =~ /Hostname/
      stdout.should =~ /Provider/
      stdout.should =~ /IP/

      stdout.should =~ /slicey/
      stdout.should =~ /Slicehost/
      stdout.should =~ /174\.143\.145\.37/
    end
  end
end