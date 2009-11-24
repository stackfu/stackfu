require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestPublishCommand < Test::Unit::TestCase
  context "Publish command" do
    should "check if stack exists before publishing" do
      setup_stack
      with_stacks "by_name", "stack%5Bname%5D=my_stack"
      with_stack_delete "4b08748de1054e1477000006"
      with_stack_add
      
      agree_with("You already have a stack named my_stack. Do you want to update it?")
      
      command "pub"
      stdout.should =~ /Publishing stack my_stack/
      stdout.should =~ /Success/
    end
    
    should "check if stack exists but not ask the user for confirmation if --update is provided" do
      setup_stack
      with_stacks "by_name", "stack%5Bname%5D=my_stack"
      with_stack_delete "4b08748de1054e1477000006"
      with_stack_add
      
      command "pub --update"
      stdout.should =~ /Publishing stack my_stack/
      stdout.should =~ /Success/
    end
    
    should "tell the user when there's a problem deleting the stack" do
      setup_stack
      with_stacks "by_name", "stack%5Bname%5D=my_stack"
      with_stack_delete "4b08748de1054e1477000006", "server_delete_error"
      with_stack_add
      
      command "pub --update"
      stdout.should =~ /There was a problem updating your stack/
      stdout.should_not =~ /Publishing stack my_stack/
    end
    
    should "be OK when stack doesn't exist" do
      setup_stack
      with_stacks "empty", "stack%5Bname%5D=my_stack"
      with_stack_add
      
      command "pub"
      stdout.should =~ /Publishing stack my_stack/
      stdout.should =~ /Success/
    end
    
    should "abort if user responded false to check when stack exists before publishing" do
      setup_stack
      with_stacks "by_name", "stack%5Bname%5D=my_stack"
      with_stack_add
      
      disagree_of("You already have a stack named my_stack. Do you want to update it?")
      
      command "pub"
      stdout.should =~ /Abort./
    end
    
    should "be aliased to pub" do
      setup_stack
      with_stacks "empty", "stack%5Bname%5D=my_stack"
      with_stack_add
      command "pub"
      stdout.should =~ /Publishing stack my_stack/
      stdout.should =~ /Success/
    end
    
    should "show an error when a stack has no scripts" do
      setup_stack :scripts => ""
      command "pub"
      stdout.should =~ /To publish a stack you have to define at least one script./
    end
    
    should "show an error when a script is not found" do
      PublishCommand.any_instance.expects(:read).with("script/sample.sh.erb").raises(Errno::ENOENT)
      setup_stack :scripts => "scripts:\n- file: sample\n  description: A script\n"
      command "pub"
      stdout.should =~ /The template file for the script 'A script' was not found./
    end
    
    should "show an error if stack.yml is not on the current folder" do
      PublishCommand.any_instance.expects(:read).with("stack.yml").raises(Errno::ENOENT)
      command "publish"
      stdout.should =~ /Couldn't find a stack on current folder./
      stdout.should =~ /Make sure you have a file named 'stack.yml'/
    end
    
    should "read stack.yml file when present" do
      setup_stack
      with_stacks "empty", "stack%5Bname%5D=my_stack"
      with_stack_add
      
      PublishCommand.any_instance.expects(:publish).with { |stack|
        stack.name.should == "my_stack"
        stack.description.should == "This will deploy my stack"
        
        stack.requirements.size.should == 1
        stack.requirements.first.attributes['type'].should == "directory"
        stack.requirements.first.data.should == "/var"

        stack.controls.size.should == 2
        stack.controls.first.name.should == "nome"
        stack.controls.first.label.should == "Nome"
        stack.controls.first._type.should == "Textbox"
        stack.controls.last._type.should == "Numericbox"

        stack.validations.size.should == 1
        stack.validations.first.attributes['type'].should == "directory"
        stack.validations.first.data.should == "/etc/apache2"

        stack.executions.first.data.should =~ /Echoes a variable/
        true
      }.returns(true)
      
      command "publish"
      stdout.should =~ /Publishing stack my_stack/
      stdout.should =~ /Success/
    end
    
    should "report server errors" do
      setup_stack
      with_stacks "empty", "stack%5Bname%5D=my_stack"
      with_stack_add("error")

      command "publish"
      stdout.should =~ /Publishing stack my_stack/
      stdout.should =~ /Operating system can't be empty/
    end
  end

  private

  def setup_stack(options={})
    PublishCommand.any_instance.expects(:read).with("stack.yml").returns(<<-EOS)
--- 
type: stack
name: my_stack
description: "This will deploy my stack"
tags: [mine, stack, is, nice]
EOS
    PublishCommand.any_instance.expects(:read).with("config/01-controls.yml").returns(<<-EOS)
controls:
- name: nome
  label: Nome
  type: Textbox
- name: idade
  label: Idade
  type: Numericbox
EOS
    PublishCommand.any_instance.expects(:read).with("config/02-requirements.yml").returns(<<-EOS)
requirements:

- type: directory
  data: "/var"
  error: "You need /var folder before installing"
EOS
    PublishCommand.any_instance.expects(:read).with("config/03-scripts.yml").returns(options[:scripts] || <<-EOS)
scripts: 

- description: Echoer
  file: echoer
EOS
    PublishCommand.any_instance.expects(:read).with("config/04-validations.yml").returns(<<-EOS)
validations:
- type: directory
  data: "/etc/apache2"
  error: Apache was not installed properly
EOS

    unless options[:scripts]
      PublishCommand.any_instance.expects(:read).with("script/echoer.sh.erb").returns(<<-EOS)
#
# echoe.sh
# Echoes a variable
#

echo "<%= nome %> is <%= age %> years old"
EOS
    end
  end
end