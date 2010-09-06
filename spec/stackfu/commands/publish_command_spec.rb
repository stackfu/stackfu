# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::PublishCommand do
  
  it "checks if script exists before publishing" do
    prepare(:get, '/scripts/firewall.json', '/scripts/firewall.json')
    prepare(:delete, '/scripts/firewall.json', '/scripts/delete.json')
    prepare(:post, '/scripts.json', '/scripts/create.json')
    
    setup_script(:script_name => 'firewall')
  
    agree_with("You already have a script named firewall. Do you want to update it?")
  
    command "pub"
    stdout.should =~ /Publishing script firewall/
    stdout.should =~ /Success/
  end
  
  def setup_script(options={})
    StackFu::Commands::PublishCommand.any_instance.expects(:read).with("script.yml").returns(<<-EOS)
--- 
type: stack
name: #{options[:"script_name"] || "my_script"}
description: "This will deploy my script"
EOS
    StackFu::Commands::PublishCommand.any_instance.expects(:read).with("config/01-controls.yml").returns(<<-EOS)
controls:
- name: nome
  label: Nome
  type: Textbox
- name: idade
  label: Idade
  type: Numericbox
EOS
    StackFu::Commands::PublishCommand.any_instance.expects(:read).with("config/02-requirements.yml").returns(<<-EOS)
requirements:

- type: directory
  data: "/var"
  error: "You need /var folder before installing"
EOS
    StackFu::Commands::PublishCommand.any_instance.expects(:read).with("config/03-executions.yml").returns(options[:scripts] || <<-EOS)
executions: 

- description: Echoer
  file: echoer
EOS
    StackFu::Commands::PublishCommand.any_instance.expects(:read).with("config/04-validations.yml").returns(<<-EOS)
validations:
- type: directory
  data: "/etc/apache2"
  error: Apache was not installed properly
EOS

    unless options[:scripts]
      StackFu::Commands::PublishCommand.any_instance.expects(:read).with("executables/echoer.sh.erb").returns(<<-EOS)
#
# echoe.sh
# Echoes a variable
#

echo "<%= nome %> is <%= age %> years old"
EOS
    end
  end
end