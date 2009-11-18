require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestPublishCommand < Test::Unit::TestCase
  context "Publish command" do
    should "be aliased to pub"
    
    should "show an error if stack.yml is not on the current folder" do
      PublishCommand.any_instance.expects(:read).with("stack.yml").raises(Errno::ENOENT)
      command "publish"
      stdout.should =~ /Couldn't find a stack on current folder. Make sure you have a file named 'stack.yml'/
    end
    
    should "read stack.yml file when present" do
      setup_stack
      with_stack_add
      command "publish"
    end
    
    should "report server errors" do
      setup_stack
      with_stack_add("error")
      command "publish"
      stdout.should =~ /Operating system can't be empty/
    end
    
    # assemble the stack object
    # publish the stack using REST
  end

  private

  def setup_stack
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
control: Textbox
- name: idade
label: Idade
control: Numericbox
EOS
    PublishCommand.any_instance.expects(:read).with("config/02-requirements.yml").returns(<<-EOS)
requirements:

- type: folder
data: "/var"
error: "You need /var folder before installing"
EOS
    PublishCommand.any_instance.expects(:read).with("config/03-scripts.yml").returns(<<-EOS)
scripts: 

- description: Echoer
file: echoer
EOS
    PublishCommand.any_instance.expects(:read).with("config/04-validations.yml").returns(<<-EOS)
validations:
- type: folder
data: "/etc/apache2"
error: Apache was not installed properly
EOS
  end
end