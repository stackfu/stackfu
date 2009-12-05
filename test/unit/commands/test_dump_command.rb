require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestDumpCommand < Test::Unit::TestCase
  context "validations" do
    should "map 'dump' to DumpCommand" do
      Command.create("dump").class.should == DumpCommand
    end
    
    should "require a parameter with stack or plugin" do
      command "dump"
      stdout.should =~ /You have to tell what you want to dump: a stack or a plugin/
    end

    should "require a parameter with stack or plugin" do
      command "dump my_girlfriend"
      stdout.should =~ /You have to tell what you want to dump: a stack or a plugin/
    end
  end

  context "dump a stack requirements" do
    should "require the stack name" do
      command "dump stack"
      stdout.should =~ /requires 1 parameter\./
      stdout.should =~ /stackfu dump stack STACK_NAME/
    end

    should "display an error when the stack is not found" do
      with_stacks("empty", "stack%5Bname%5D=my_stack")
      command "dump stack my_stack"
      stdout.should =~ /Stack 'my_stack' was not found/
    end

    should "display the stack name on the error message" do
      with_stacks("empty", "stack%5Bname%5D=my_other_stack")
      command "dump stack my_other_stack"
      stdout.should =~ /Stack 'my_other_stack' was not found/
    end
    
    should "ask before overwriting an existing folder" do
      with_stacks("multiple", "stack%5Bname%5D=my_stack")
      
      DumpCommand.any_instance.expects(:directory?).with("my_stack").returns(true)
      disagree_of("There is already a folder called 'my_stack'. Do you want to overwrite its contents?")
      
      command "dump stack my_stack"
      stdout.should =~ /Aborted./
    end
  end
  
  context "a valid dump stack command" do
    setup do
      with_stacks("multiple", "stack%5Bname%5D=my_stack")
    end
    
    should "create a directory structure that describes the stack" do
      expects_stack("stackfu-installer")
      with_stacks("stackfu-installer", "stack%5Bname%5D=stackfu-installer")

      command "dump stack stackfu-installer"
      stdout.should =~ /^\tcreate  stackfu-installer\//
      stdout.should =~ /^\tcreate  stackfu-installer\/stack.yml/
      stdout.should =~ /^\tcreate  stackfu-installer\/config\//
      stdout.should =~ /^\tcreate  stackfu-installer\/config\/01-controls.yml/
      stdout.should =~ /^\tcreate  stackfu-installer\/config\/02-requirements.yml/
      stdout.should =~ /^\tcreate  stackfu-installer\/config\/03-scripts.yml/
      stdout.should =~ /^\tcreate  stackfu-installer\/config\/04-validations.yml/
      stdout.should =~ /^\tcreate  stackfu-installer\/script\//
      stdout.should =~ /^\tcreate  stackfu-installer\/script\//
      stdout.should =~ /^\tcreate  stackfu-installer\/script\/dotfiles_installation.sh.erb/
      stdout.should =~ /^\tcreate  stackfu-installer\/script\/github_credentials_setup.sh.erb/
      stdout.should =~ /^\tcreate  stackfu-installer\/script\/nginx_and_passenger.sh.erb/
      stdout.should =~ /^\tcreate  stackfu-installer\/script\/redis_installation.sh.erb/
      stdout.should =~ /^\tcreate  stackfu-installer\/script\/resque_installation.sh.erb/
      stdout.should =~ /^\tcreate  stackfu-installer\/script\/ruby_environment.sh.erb/
      stdout.should =~ /^\tcreate  stackfu-installer\/script\/stackfu.sh.erb/
      stdout.should =~ /^Stack stackfu-installer dumped successfully/
    end
  end
  
  context "helper methods" do
    should "create a folder" do
      Dir.expects(:mkdir).with("my_stack")
      File.stubs(:directory?).once.returns(false)
      dc = DumpCommand.new(["stack", "my_stack"])
      dc.send(:create_folder, "my_stack")
    end

    should "create a folder based on the param" do
      Dir.expects(:mkdir).with("my_stack_yey")
      dc = DumpCommand.new(["stack", "my_stack"])
      dc.send(:create_folder, "my_stack_yey")
    end

    should "create a file" do
      file = mock("stack.yml")
      
      File.expects(:open).with("stack.yml", "w").yields(file)
      file.expects(:write).with("abcdef")
      
      dc = DumpCommand.new(["stack", "my_stack"])
      dc.send(:create_file, "stack.yml", "abcdef")
    end
  end
  
  private
  
  def expects_stack(stack_name)
    DumpCommand.any_instance.expects(:directory?).with(stack_name).returns(false)
    
    expects_create_folder stack_name
    expects_create_yaml_file "#{stack_name}/stack.yml"
    
    expects_create_folder stack_name, "config"
    expects_create_yaml_file "#{stack_name}/config/01-controls.yml"
    expects_create_yaml_file "#{stack_name}/config/02-requirements.yml"
    expects_create_yaml_file "#{stack_name}/config/03-scripts.yml"
    expects_create_yaml_file "#{stack_name}/config/04-validations.yml"

    expects_create_folder stack_name, "script"
    expects_create_file "#{stack_name}/script/dotfiles_installation.sh.erb"
    expects_create_file "#{stack_name}/script/github_credentials_setup.sh.erb"
    expects_create_file "#{stack_name}/script/nginx_and_passenger.sh.erb"
    expects_create_file "#{stack_name}/script/redis_installation.sh.erb"
    expects_create_file "#{stack_name}/script/resque_installation.sh.erb"
    expects_create_file "#{stack_name}/script/ruby_environment.sh.erb"
    expects_create_file "#{stack_name}/script/stackfu.sh.erb"
  end
  
  def expects_create_file(file_name)
    DumpCommand.any_instance.expects(:write_file).with(file_name, load(file_name))
  end
  
  def expects_create_yaml_file(file_name)
    DumpCommand.any_instance.expects(:write_file).with do |name, attrs|
      ok = name == file_name
      ok = ok && YAML::load(load(file_name)) == YAML::load(attrs)

      # unless ok
      #   d "Expected attrs: #{YAML::load(load(file_name)).inspect}"
      #   d "     Got attrs: #{YAML::load(attrs).inspect}"
      # end

      ok
    end
  end
  
  def expects_create_folder(stack_name, dir_name="")
    dir_name = "/#{dir_name}" if dir_name.present?
    DumpCommand.any_instance.expects(:mkdir).with("#{stack_name}#{dir_name}")
  end
  
  def load(file)
    File.open(File.join(File.dirname(__FILE__), "../../fixtures/stack", file)).read
  end
end