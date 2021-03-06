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
    
    it "dumps another user's script when using user/script" do
      prepare :get, "/users/fcoury/firewall.json", "/scripts/firewall.json"

      StackFu::Commands::DumpCommand.any_instance.tap do |cmd|
        cmd.expects(:directory?).with("firewall").returns(false)
        cmd.stubs(:write_file)
      end

      command "dump fcoury/firewall"
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
      stdout.should =~ /^Success: Script fcoury\/firewall dumped/
    end
    
    it "reports script not found" do
      prepare :get, "/users/fcoury/firewall.json", "/scripts/script_not_found.json"
      
      command "dump fcoury/firewall"
      stdout.should =~ /Script 'fcoury\/firewall' was not found/
    end
    
    it "dumps required" do
      prepare :get, "/scripts/pwned.json"

      StackFu::Commands::DumpCommand.any_instance.tap do |cmd|
        cmd.expects(:directory?).with("pwned").returns(false)
        cmd.expects(:write_file).at_least_once.with() do |name, contents|
          if name == 'pwned/config/01-controls.yml'
            controls = YAML.load(contents)["controls"]

            grade_ctrl = controls.select { |c| c['name'] == 'grade' }.first
            grade_ctrl["required"].should == 'true'
          end
          true
        end
      end
      
      # TODO: check create file for controls

      command "dump pwned"
    end
    
    it "dumps tags" do
      prepare :get, "/scripts/pwned.json"

      StackFu::Commands::DumpCommand.any_instance.tap do |cmd|
        cmd.expects(:directory?).with("pwned").returns(false)
        cmd.expects(:write_file).at_least_once.with() do |name, contents|
          if name == 'pwned/script.yml'
            controls = YAML.load(contents)
            controls['tags'].should == ['one', 'two']
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
            
            options = controls.select { |c| c['name'] == 'school' }.first["options"]
            options.should_not be_nil
            
            grade_ctrl = controls.select { |c| c['name'] == 'grade' }.first
            
            validations = grade_ctrl["validations"]
            validations.should_not be_nil
            validations.keys.size.should == 2

            validations["matches"].should  == "^[A|B|C]$"
            validations["maxlength"].should == 1

            validation_messages = grade_ctrl["validation_messages"]

            validation_messages.should_not be_nil
            validation_messages.keys.size.should == 2

            validation_messages["matches"].should   == "must be A, B or C"
            validation_messages["maxlength"].should == "must have 1 or less characters!"
          end
          true
        end
      end
      
      # TODO: check create file for controls

      command "dump pwned"
    end
  end
end