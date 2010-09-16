# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::DumpCommand do
  it "requires a parameter" do
    command "dump"
    stdout.should =~ /You have to tell which script you want to dump/
  end
  
  it "displays an error when the stack is not found" do
    prepare :get, "/scripts/my_script.json", "/scripts/not_found.json"
    command "dump my_script"
    stdout.should =~ /Script 'my_script' was not found/
  end

  it "asks before overwriting an existing folder" do
    prepare :get, "/scripts/firewall.json", "/scripts/firewall.json"
    
    StackFu::Commands::DumpCommand.any_instance.expects(:directory?).with("firewall").returns(true)
    disagree_of("There is already a folder called 'firewall'. Do you want to overwrite its contents?")
    
    command "dump firewall"
    stdout.should =~ /Aborted./
  end
  
  context "valid script" do
    it "creates a directory structure that describes the stack" do
      prepare :get, "/scripts/firewall.json", "/scripts/firewall.json"

      StackFu::Commands::DumpCommand.any_instance.expects(:directory?).with("firewall").returns(false)

      command "dump firewall"
      stdout.should =~ /^\tcreate  firewall\//
      stdout.should =~ /^\tcreate  firewall\/script.yml/
      stdout.should =~ /^\tcreate  firewall\/config\//
      stdout.should =~ /^\tcreate  firewall\/config\/01-controls.yml/
      stdout.should =~ /^\tcreate  firewall\/config\/02-requirements.yml/
      stdout.should =~ /^\tcreate  firewall\/config\/03-executions.yml/
      stdout.should =~ /^\tcreate  firewall\/config\/04-validations.yml/
      stdout.should =~ /^\tcreate  firewall\/executables\//
      stdout.should =~ /^\tcreate  firewall\/executables\//
      stdout.should =~ /^\tcreate  firewall\/executables\/install_ufw.sh.erb/
      stdout.should =~ /^\tcreate  firewall\/executables\/configure_ufw.sh.erb/
      stdout.should =~ /^Success: Script firewall dumped/
    end
  end
end