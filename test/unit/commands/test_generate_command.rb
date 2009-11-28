require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestGenerateCommand < Test::Unit::TestCase
  context "empty command" do
    should "present the options" do
      command "generate"
      stdout.should =~ /You have to tell what you want to generate/
      stdout.should =~ /stack/
      stdout.should =~ /plugin/
    end
  end
  
  %w(stack plugin).each do |what|
    context "command generate #{what}" do
      ## Normal behavior

      should "show the requirement parameter if none given" do
        command "generate #{what}"
        stdout.should =~ /#{what.upcase}_NAME/
      end

      should "generate the #{what} file and the script folder even when no script is given" do
        expect_create :dir => "test", :file => "#{what}.yml"
        expect_create :dir => "test/script"
        expect_create :dir => "test/config", :file => "01-controls.yml"
        expect_create :dir => "test/config", :file => "02-requirements.yml"
        expect_create :dir => "test/config", :file => "03-scripts.yml"
        expect_create :dir => "test/config", :file => "04-validations.yml"

        command "generate #{what} test"
        stdout.should =~ /#{what.titleize} test created successfully/
      end

      should "generate proper tree with one scripts passed" do
        expect_create :dir => "other", :file => "#{what}.yml"
        expect_create :dir => "other/script", :file => "install_counter_strike_server.sh.erb"
        expect_create :dir => "other/config", :file => "01-controls.yml"
        expect_create :dir => "other/config", :file => "02-requirements.yml"
        expect_create :dir => "other/config", :file => "03-scripts.yml", 
          :contents => [/install_counter_strike_server/, /Install Counter Strike Server/]
        expect_create :dir => "other/config", :file => "04-validations.yml"

        command "generate #{what} other install_counter_strike_server:script"
        stdout.should =~ /#{what.titleize} other created successfully/
      end

      should "generate proper tree with scripts and controls" do
        expect_create :dir => "test", :file => "#{what}.yml"
        expect_create :dir => "test/script", :file => "install_counter_strike_server.sh.erb"
        expect_create :dir => "test/script", :file => "show_me_the_money.sh.erb"
        expect_create :dir => "test/config", :file => "01-controls.yml",
          :contents => [
            /name: clan_name/,     /label: Clan Name/,     /type: Textbox/,
            /name: clan_password/, /label: Clan Password/, /type: Password/
          ]
        expect_create :dir => "test/config", :file => "02-requirements.yml"
        expect_create :dir => "test/config", :file => "03-scripts.yml", 
          :contents => [
            /install_counter_strike_server/, /Install Counter Strike Server/,
            /show_me_the_money/,             /Show Me The Money/
          ]
        expect_create :dir => "test/config", :file => "04-validations.yml"

        command "generate #{what} test clan_name:textbox clan_password:password install_counter_strike_server:script show_me_the_money:script"
      end

      ## Error conditions

      should "raise an error message if one of the params is unknown" do
        command "generate #{what} test abcdef"
        stdout.should =~ /Don't know how to generate a #{what} with abcdef. Use 'stackfu help generate' for more information./
      end

      should "raise an error message if one of the params is of invalid type" do
        command "generate #{what} test yogurt:food"
        stdout.should =~ /Don't know how to generate a #{what} with food yogurt. Use 'stackfu help generate' for more information./
      end

      should "raise a nice error when mkdir fails" do
        expect_create :dir => "test", :file => "#{what}.yml", :raise => [IOError, "Error description"]
        command "generate #{what} test"
        stdout.should =~ /There was an error creating your #{what}: Error description/
      end

      should "raise a nice error when mkdir fails because there is a file with same name" do
        expect_create :dir => "test", :file => "#{what}.yml", :raise => [Errno::EEXIST, "Error description"]
        command "generate #{what} test"
        stdout.should =~ /There was an error creating your #{what}: File exists - Error description/
      end
    end
  end
  
  private
  def expect_create(opts={})
    expect = GenerateCommand.any_instance.expects(:create).with do |dir, file, contents|
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