require File.dirname(__FILE__) + '/../../test_helper.rb'

class SampleCmd < Command
end

class TestCommand < Test::Unit::TestCase
  should "return true to params? if params given" do
    SampleCmd.new(["hello", "world"]).params?.should be_true
  end
  
  should "return false to params? if params given" do
    SampleCmd.new(["--hello", "--world"]).params?.should be_false
  end
  
  should "allow command with no subcommand" do
    cmd = SampleCmd.new(["--force"])
    cmd.subcommand.should == :default
    cmd.parameters.should == []
    cmd.options.should == { :force => true }
    
    cmd = SampleCmd.new(["mine", "yellow", "--azul=b"])
    cmd.subcommand.should == :mine
    cmd.parameters.should == ["yellow"]
    cmd.options.should == { :azul => "b" }
  end
  
  should "parse as parameter if = is present" do
    cmd = SampleCmd.new(["--force", "--ssh_passphrase="])
    cmd.options.should == { :force => true, :ssh_passphrase => "" }
  end
  
  should "parse subcommand and options" do
    cmd = SampleCmd.new(["copy", "--force", "/var/opt/music/mine.mp3", "/home/fcoury"])
    cmd.subcommand.should == :copy
    cmd.parameters.should == ["/var/opt/music/mine.mp3", "/home/fcoury"]
    cmd.options.should == { :force => true }

    cmd = SampleCmd.new(["move", "/var/log/1.log", "--mode=FAILSAFE", "/var/log/one.log"])
    cmd.subcommand.should == :move
    cmd.parameters.should == ["/var/log/1.log", "/var/log/one.log"]
    cmd.options.should == { :mode => "FAILSAFE" }
  end
  
  should "allow commands to have aliases" do
    SampleCmd.aliases "smp", "sampoo"
    Command.create("smp").class.should == SampleCmd
    Command.create("sampoo").class.should == SampleCmd
  end
  
  should "be valid if only a default subcommand exists" do
    SampleCmd.new.should be_valid
  end
  
  should "allow named parameters" do
    class NewCmd < Command
      subcommand :move, :required_parameters => [:provider, :server_name]
    end

    lambda { 
      cmd = NewCmd.new(["move"]) 
    }.should raise_error(Exceptions::InvalidCommand, /requires 2 parameters/)
  end
  
  should "allow subcommand aliases" do
    class Cmd < Command
      alias_subcommand :list => :default
    end
    
    cmd = Cmd.new(["list"])
    cmd.subcommand.should == :default
  end
  
  should "throw a specific exception when subcommand doesn't exist" do
    class ListCommand < Command
    end
    
    lambda {
      ListCommand.new(["find"]).run
    }.should raise_error(Exceptions::InvalidCommand, /Command list doesn't have a subcommand "find". Try "stackfu list help" for more information./)
  end
  
  should "allow the error message for inexistent subcommand to be customized" do
    class ExampleCommand < Command
      error_messages :missing_subcommand => "There's no such thing as %s"
    end

    lambda {
      ExampleCommand.new(["test"]).run
    }.should raise_error(Exceptions::InvalidCommand, /There's no such thing as test/)
  end
  
  should "allow the error message for missing params to be customized" do
    class ExampleCommand < Command
      subcommand :test, :required_parameters => [:sex, :age]
      error_messages :missing_params => "You have to provide sex and age, dude!"
    end

    lambda {
      ExampleCommand.new(["test"]).run
    }.should raise_error(Exceptions::InvalidCommand, /You have to provide sex and age, dude!/)
  end
end
