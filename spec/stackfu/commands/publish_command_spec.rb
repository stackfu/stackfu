# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::PublishCommand do

  context 'validating script.yml' do
    it "validates the name for invalid chars" do
      setup_one 'missing', 'script.yml', "name: My Fair Scripty\ntype: script"
      setup_one 'missing', 'config/01-controls.yml', ''
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid value for field name: only lower case chars, numbers and underscores are allowed/
    end

    
    it "checks script.yml format" do
      setup_fixture('invalid')
      setup_one 'missing', 'config/01-controls.yml', ''
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /the file descriptor has the wrong format/
    end

    it "checks for valid YAML file" do
      setup_one 'missing', 'script.yml', 'name: myscript, type: yadda'
      setup_one 'missing', 'config/01-controls.yml', ''
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''

      command "pub"
      stdout.should =~ /invalid YAML document. Parse error: syntax error on line 0, col 21/
    end

    it "checks required script field 'name'" do
      setup_fixture('missing')

      command "pub"
      stdout.should =~ /missing field name/
    end

    it "checks required script field 'type'" do
      setup_one 'missing', 'script.yml', 'name: myscript'
      setup_one 'missing', 'config/01-controls.yml', ''
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''

      command "pub"
      stdout.should =~ /missing field type/
    end

    it "checks content of field 'type'" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: yadda}'
      setup_one 'missing', 'config/01-controls.yml', ''
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''

      command "pub"
      stdout.should =~ /invalid value for field type/
    end
  end
  
  context 'validating 01-controls.yml' do
    it "checks file format" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'hey you'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid format/
    end

    it "checks for invalid YML" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'name: myscript, type: yadda'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid YAML document. Parse error: syntax error on line 0, col 21/
    end
    
    it "checks for missing controls key" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'other: [{name: control}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid format/
    end

    it "assures that controls is an array" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'other: {name: control}'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid format/
    end

    it "checks for missing name" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{type: Textbox}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /missing name for control 1/
    end
    
    it "checks for misformatted validations" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', <<-EOS
controls: 
  - type: Textbox
    name: myscript
    validations: abcdef
EOS
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid validations format for Textbox myscript/
    end

    it "checks for misformatted validations array" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', <<-EOS
controls: 
  - type: Textbox
    name: myscript
    validations: [abcdef, ghij]
EOS
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''

      command "pub"
      stdout.should =~ /invalid validations format for Textbox myscript/
    end

    it "checks for unknown validation type" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', <<-EOS
controls: 
  - type: Textbox
    name: myscript
    validations:
      - popeye: olivia
      - charm: ok
EOS
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''

      command "pub"
      stdout.should =~ /invalid validation type for Textbox myscript: popeye/
      stdout.should =~ /invalid validation type for Textbox myscript: charm/
    end

    it "checks for missing options (Radio)" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{type: Radio, name: radio}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /missing options for Radio control radio/
    end

    it "checks for misformatted options (Radio)" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{type: Radio, name: radio, options: abcdef}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid options format for Radio control radio/
    end
    
    it "checks for misformatted options (Radio)" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{type: Radio, name: radio, options: [one, two]}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid options format for Radio control radio/
    end

    it "checks for missing options (Combobox)" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{type: Combobox, name: combobox}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /missing options for Combobox control combobox/
    end

    it "checks for misformatted options (Combobox)" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{type: Combobox, name: combobox, options: abcdef}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid options format for Combobox control combobox/
    end
    
    it "checks for misformatted options (Combobox)" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{type: Combobox, name: combobox, options: [one, two]}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid options format for Combobox control combobox/
    end

    it "checks for missing type" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{name: control}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /missing type for control control/
    end

    it "checks for invalid type" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: [{name: control, type: RockOn}]'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid type RockOn for control control/
    end
  end
  
  context 'validating 02-requirements.yml' do
    it "checks file format" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', 'hey you'
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid format/
    end
    
    it "checks for invalid YAML" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', 'name: myscript, - type: yadda'
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid YAML document. Parse error: syntax error on line 0, col 23/
    end
    
    it "checks for missing type" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', "requirements:\n- {data: x, type: DirExists}\n- data: x"
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /missing type for requirement 2/
    end
  end
  
  context 'validating 03-executions.yml' do
    it "checks file format" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', 'requirements: []'
      setup_one 'missing', 'config/03-executions.yml', 'hey you'
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid format/
    end
    
    it "checks for invalid YAML" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', 'requirements: []'
      setup_one 'missing', 'config/03-executions.yml', 'name: myscript, - type: yadda'
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /invalid YAML document. Parse error: syntax error on line 0, col 23/
    end
    
    it "checks for missing description" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', 'requirements: []'
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}\n- file: execution"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /missing description for execution execution/
    end
    
    it "checks for missing file" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', ''
      setup_one 'missing', 'config/02-requirements.yml', 'requirements: []'
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}\n- description: execution"
      setup_one 'missing', 'config/04-validations.yml', ''
      
      command "pub"
      stdout.should =~ /missing file for execution 2/
    end
  end
  
  context 'validating 04-validations.yml' do
    it "checks file format" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', ''
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', 'hey you'
      
      command "pub"
      stdout.should =~ /invalid format/
    end
    
    it "checks for invalid YAML" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', 'requirements: []'
      setup_one 'missing', 'config/03-executions.yml', "executions:\n- {file: x, description: y}"
      setup_one 'missing', 'config/04-validations.yml', 'name: myscript, - type: yadda'
      
      command "pub"
      stdout.should =~ /invalid YAML document. Parse error: syntax error on line 0, col 23/
    end
    
    it "checks for missing type" do
      setup_one 'missing', 'script.yml', '{name: myscript, type: script}'
      setup_one 'missing', 'config/01-controls.yml', 'controls: []'
      setup_one 'missing', 'config/02-requirements.yml', 'requirements: []'
      setup_one 'missing', 'config/03-executions.yml', ""
      setup_one 'missing', 'config/04-validations.yml', "validations:\n- {data: x, type: DirExists}\n- data: x"
      
      command "pub"
      stdout.should =~ /missing type for validation 2/
    end
  end
  
  it "reports all errors" do
    setup_one 'missing', 'script.yml', '{name: myscript}'
    setup_one 'missing', 'config/01-controls.yml', 'controls: []'
    setup_one 'missing', 'config/02-requirements.yml', 'requirements: []'
    setup_one 'missing', 'config/03-executions.yml', ""
    setup_one 'missing', 'config/04-validations.yml', "validations:\n- {data: x, type: DirExists}\n- data: x"
    
    command "pub"
    stdout.should =~ /missing field type/
    stdout.should =~ /missing type for validation 2/
  end
  
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
  
  private
  
  def setup_fixture(script)
    setup_one script, "script.yml"  
    setup_one script, "config/01-controls.yml"
    setup_one script, "config/02-requirements.yml"
    setup_one script, "config/03-executions.yml"
    setup_one script, "config/04-validations.yml"
  end
  
  def setup_one(script, expect, contents=nil)
    return unless fixture?("scripts/#{script}/#{expect}")
    contents ||= read_fixture("scripts/#{script}/#{expect}")
      
    StackFu::Commands::PublishCommand.any_instance.stubs(:read).with(expect).returns(contents)
  end
  
  
  def setup_script(options={})
    StackFu::Commands::PublishCommand.any_instance.stubs(:read).with("script.yml").returns(<<-EOS)
--- 
type: script
name: #{options[:"script_name"] || "my_script"}
description: "This will deploy my script"
EOS
    StackFu::Commands::PublishCommand.any_instance.stubs(:read).with("config/01-controls.yml").returns(<<-EOS)
controls:
- name: nome
  label: Nome
  type: Textbox
- name: idade
  label: Idade
  type: Numericbox
EOS
    StackFu::Commands::PublishCommand.any_instance.stubs(:read).with("config/02-requirements.yml").returns(<<-EOS)
requirements:

- type: DirExists
  data: "/var"
  error: "You need /var folder before installing"
EOS
    StackFu::Commands::PublishCommand.any_instance.stubs(:read).with("config/03-executions.yml").returns(options[:scripts] || <<-EOS)
executions: 

- description: Echoer
  file: echoer
EOS
    StackFu::Commands::PublishCommand.any_instance.stubs(:read).with("config/04-validations.yml").returns(<<-EOS)
validations:
- type: DirExists
  data: "/etc/apache2"
  error: Apache was not installed properly
EOS

    unless options[:scripts]
      StackFu::Commands::PublishCommand.any_instance.stubs(:read).with("executables/echoer.sh.erb").returns(<<-EOS)
#
# echoe.sh
# Echoes a variable
#

echo "<%= nome %> is <%= age %> years old"
EOS
    end
  end
end