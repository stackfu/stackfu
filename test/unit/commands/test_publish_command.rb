require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestPublishCommand < Test::Unit::TestCase

  %w(plugin stack).each do |what|
    define_method("setup_#{what}") do |*options|
      options = options.pop || {}
      PublishCommand.any_instance.expects("#{what}?").returns(true)
      PublishCommand.any_instance.expects("#{['stack', 'plugin'] - [what]}?").returns(false)

      PublishCommand.any_instance.expects(:read).with("#{what}.yml").returns(<<-EOS)
--- 
type: stack
name: #{options[:"#{what}_name"] || "my_#{what}"}
description: "This will deploy my #{what}"
tags: [mine, #{what}, is, nice]
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
  
  should "return true for plugin? if file plugin.yml exists" do
    File.expects(:exists?).with("plugin.yml").returns(true)
    PublishCommand.new.plugin?.should be_true
  end
    
  should "return true for stack? if file plugin.yml exists" do
    File.expects(:exists?).with("stack.yml").returns(true)
    PublishCommand.new.stack?.should be_true
  end

  %w(stack plugin).each do |what|
    context "Publish command for a #{what}" do
      should "check if #{what} exists before publishing" do
        send "setup_#{what}"
        send "with_#{what}s", "by_name", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_delete", "4b08748de1054e1477000006"
        send "with_#{what}_add"
      
        agree_with("You already have a #{what} named my_#{what}. Do you want to update it?")
      
        command "pub"
        stdout.should =~ /Publishing #{what} my_#{what}/
        stdout.should =~ /Success/
      end
    
      should "check if #{what} exists but not ask the user for confirmation if --update is provided" do
        send "setup_#{what}"
        send "with_#{what}s", "by_name", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_delete", "4b08748de1054e1477000006"
        send "with_#{what}_add"
      
        command "pub --update"
        stdout.should =~ /Publishing #{what} my_#{what}/
        stdout.should =~ /Success/
      end
    
      should "tell the user when there's a problem deleting the #{what}" do
        send "setup_#{what}"
        send "with_#{what}s", "by_name", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_delete", "4b08748de1054e1477000006", "server_delete_error"
        send "with_#{what}_add"
      
        command "pub --update"
        stdout.should =~ /There was a problem updating your #{what}/
        stdout.should_not =~ /Publishing #{what} my_#{what}/
      end
    
      should "be OK when #{what} doesn't exist" do
        send "setup_#{what}"
        send "with_#{what}s", "empty", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_add"
      
        command "pub"
        stdout.should =~ /Publishing #{what} my_#{what}/
        stdout.should =~ /Success/
      end
    
      should "abort if user responded false to check when #{what} exists before publishing" do
        send "setup_#{what}"
        send "with_#{what}s", "by_name", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_add"
      
        disagree_of("You already have a #{what} named my_#{what}. Do you want to update it?")
      
        command "pub"
        stdout.should =~ /Abort./
      end
    
      should "show the correct #{what} name" do
        send "setup_#{what}", "#{what}_name".to_sym => "bli#{what}"
        send "with_#{what}s", "by_name_other", "#{what}%5Bname%5D=bli#{what}"
        send "with_#{what}_add"
      
        disagree_of("You already have a #{what} named bli#{what}. Do you want to update it?")
      
        command "pub"
        stdout.should =~ /Abort./
      end
    
      should "be aliased to pub" do
        send "setup_#{what}"
        send "with_#{what}s", "empty", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_add"
        command "pub"
        stdout.should =~ /Publishing #{what} my_#{what}/
        stdout.should =~ /Success/
      end
    
      should "show an error when a #{what} has no scripts" do
        send "setup_#{what}", :scripts => ""
        command "pub"
        stdout.should =~ /To publish a #{what} you have to define at least one script./
      end
    
      should "show an error when a script is not found" do
        PublishCommand.any_instance.expects(:read).with("script/sample.sh.erb").raises(Errno::ENOENT)
        send "setup_#{what}", :scripts => "scripts:\n- file: sample\n  description: A script\n"
        command "pub"
        stdout.should =~ /The template file for the script 'A script' was not found./
      end
    
      should "show an error if there's no stack.yml and no plugin.yml on the current folder" do
        PublishCommand.any_instance.expects(:stack?).returns(false)
        PublishCommand.any_instance.expects(:plugin?).returns(false)
      
        command "publish"
        stdout.should =~ /Couldn't find an item to publish on current folder./
        stdout.should =~ /Make sure you have a file named 'stack.yml'/
      end
    
      should "read #{what}.yml file when present" do
        send "setup_#{what}"
        send "with_#{what}s", "empty", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_add"
      
        PublishCommand.any_instance.expects(:publish).with { |stack|
          stack.name.should == "my_#{what}"
          stack.description.should == "This will deploy my #{what}"
        
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
        stdout.should =~ /Publishing #{what} my_#{what}/
        stdout.should =~ /Success/
      end
    
      should "report server errors" do
        send "setup_#{what}"
        send "with_#{what}s", "empty", "#{what}%5Bname%5D=my_#{what}"
        send "with_#{what}_add", "error"

        command "publish"
        stdout.should =~ /Publishing #{what} my_#{what}/
        stdout.should =~ /Operating system can't be empty/
      end
    end
  end
  # private

#   def send "setup_#{what}"(options={})
#     PublishCommand.any_instance.expects(:read).with("stack.yml").returns(<<-EOS)
# --- 
# type: stack
# name: #{options[:stack_name] || "my_stack"}
# description: "This will deploy my stack"
# tags: [mine, stack, is, nice]
# EOS
#     PublishCommand.any_instance.expects(:read).with("config/01-controls.yml").returns(<<-EOS)
# controls:
# - name: nome
#   label: Nome
#   type: Textbox
# - name: idade
#   label: Idade
#   type: Numericbox
# EOS
#     PublishCommand.any_instance.expects(:read).with("config/02-requirements.yml").returns(<<-EOS)
# requirements:
# 
# - type: directory
#   data: "/var"
#   error: "You need /var folder before installing"
# EOS
#     PublishCommand.any_instance.expects(:read).with("config/03-scripts.yml").returns(options[:scripts] || <<-EOS)
# scripts: 
# 
# - description: Echoer
#   file: echoer
# EOS
#     PublishCommand.any_instance.expects(:read).with("config/04-validations.yml").returns(<<-EOS)
# validations:
# - type: directory
#   data: "/etc/apache2"
#   error: Apache was not installed properly
# EOS
# 
#     unless options[:scripts]
#       PublishCommand.any_instance.expects(:read).with("script/echoer.sh.erb").returns(<<-EOS)
# #
# # echoe.sh
# # Echoes a variable
# #
# 
# echo "<%= nome %> is <%= age %> years old"
# EOS
#     end
#   end


end