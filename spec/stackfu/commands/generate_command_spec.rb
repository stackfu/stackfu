# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::GenerateCommand do
  it "shown an error if no name is given" do
    command "generate"
    stdout.should =~ /Missing script name./
  end
  
  it "generates the script file and folder when no executables are given" do
    expect_create :dir => "test", :file => "script.yml"
    expect_create :dir => "test/executables"
    expect_create :dir => "test/config", :file => "01-controls.yml"
    expect_create :dir => "test/config", :file => "02-requirements.yml"
    expect_create :dir => "test/config", :file => "03-executions.yml"
    expect_create :dir => "test/config", :file => "04-validations.yml"

    command "generate test"
    stdout.should =~ /Script test created successfully/
  end
  
  it "generates proper tree with one executable passed" do
    expect_create :dir => "other", :file => "script.yml"
    expect_create :dir => "other/executables", :file => "install_counter_strike_server.sh.erb"
    expect_create :dir => "other/config", :file => "01-controls.yml"
    expect_create :dir => "other/config", :file => "02-requirements.yml"
    expect_create :dir => "other/config", :file => "03-executions.yml", 
      :contents => [/install_counter_strike_server/, /Install Counter Strike Server/]
    expect_create :dir => "other/config", :file => "04-validations.yml"
  
    command "generate other install_counter_strike_server:script"
    stdout.should =~ /Script other created successfully/
  end
  
  it "generates proper tree with scripts and controls" do
    expect_create :dir => "test", :file => "script.yml"
    expect_create :dir => "test/executables", :file => "install_counter_strike_server.sh.erb"
    expect_create :dir => "test/executables", :file => "show_me_the_money.sh.erb"
    expect_create :dir => "test/config", :file => "01-controls.yml",
      :contents => [
        /name: clan_name/,     /label: Clan Name/,     /type: Textbox/,
        /name: clan_password/, /label: Clan Password/, /type: Password/
      ]
    expect_create :dir => "test/config", :file => "02-requirements.yml"
    expect_create :dir => "test/config", :file => "03-executions.yml", 
      :contents => [
        /install_counter_strike_server/, /Install Counter Strike Server/,
        /show_me_the_money/,             /Show Me The Money/
      ]
    expect_create :dir => "test/config", :file => "04-validations.yml"

    command "generate test clan_name:textbox clan_password:password install_counter_strike_server:script show_me_the_money:script"
  end
  
  it "raises an error message if one of the params is unknown" do
    command "generate test abcdef"
    stdout.should =~ /Don't know how to generate a script with abcdef. Use 'stackfu help generate' for more information./
  end
  
  it "aliases to gen" do
    command "gen test abcdef"
    stdout.should =~ /Don't know how to generate a script with abcdef. Use 'stackfu help generate' for more information./
  end
  
  it "raises an error message if one of the params is of invalid type" do
    command "generate test yogurt:food"
    stdout.should =~ /Don't know how to generate a script with food yogurt. Use 'stackfu help generate' for more information./
  end

  it "raises a nice error when mkdir fails" do
    expect_create :dir => "test", :file => "script.yml", :raise => [IOError, "Error description"]
    command "generate test"
    stdout.should =~ /Error description/
  end

  it "raises a nice error when mkdir fails because there is a file with same name" do
    expect_create :dir => "test", :file => "script.yml", :raise => [Errno::EEXIST, "Error description"]
    command "generate test"
    stdout.should =~ /File exists - Error description/
  end

  def expect_create(opts={})
    expect = StackFu::Commands::GenerateCommand.any_instance.expects(:create).with do |dir, file, contents|
      dir_match = opts[:dir] ? dir == opts[:dir] : true  
      file_match = opts[:file] ? file == opts[:file] : true
      contents_match = opts[:contents] ?
        opts[:contents].each do |c|
          break true if contents =~ c
          false
        end : true
      block_match = block_given? ? yield(dir, file, contents) : true

      its_a_match = dir_match and file_match and contents_match and block_match
    end
    
    if opts[:raise]
      expect.raises(opts[:raise].first, opts[:raise].last)
    end
  end
end