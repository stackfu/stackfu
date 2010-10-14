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
    before(:each) do
      StackFu::Commands::DumpCommand.any_instance.tap do |cmd|
        cmd.stubs(:mkdir)
      end
    end
  
    it "creates a directory structure that describes the stack" do
      prepare :get, "/scripts/firewall.json", "/scripts/firewall.json"

      StackFu::Commands::DumpCommand.any_instance.tap do |cmd|
        cmd.expects(:directory?).with("firewall").returns(false)
        cmd.stubs(:write_file)
      end

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
    
    it "dumps required" do
      prepare :get, "/scripts/pwned.json"

      StackFu::Commands::DumpCommand.any_instance.tap do |cmd|
        cmd.expects(:directory?).with("pwned").returns(false)
        cmd.expects(:write_file).at_least_once.with() do |name, contents|
          if name == 'pwned/config/01-controls.yml'
            controls = YAML.load(contents)["controls"]
            controls.each do |ctrl|
              ctrl["required"].should == 'true'
            end
          end
          true
        end
      end
      
      # TODO: check create file for controls

      command "dump pwned"
    end

    it "dumps validations" do
      prepare :get, "/scripts/pwned.json"

      StackFu::Commands::DumpCommand.any_instance.tap do |cmd|
        cmd.expects(:directory?).with("pwned").returns(false)
        cmd.expects(:write_file).at_least_once.with() do |name, contents|
          if name == 'pwned/config/01-controls.yml'
            controls = YAML.load(contents)["controls"]
            validations = controls.last["validations"]

            validations.should_not be_nil
            validations.keys.size.should == 2

            validations["matches"].should  == "^[A|B|C]$"
            validations["maxlength"].should == 1

            validation_messages = controls.last["validation_messages"]

            validation_messages.should_not be_nil
            validation_messages.keys.size.should == 2

            validation_messages["matches"].should   == "must be A, B or C"
            validation_messages["maxlength"].should == "must have 1 or less characters"
          end
          true
        end
      end
      
      # TODO: check create file for controls

      command "dump pwned"
    end
  end
end