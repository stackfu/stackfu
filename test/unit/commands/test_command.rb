require File.dirname(__FILE__) + '/../../test_helper.rb'

class SampleCmd < Command
end

class TestCommand < Test::Unit::TestCase
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
  
  should "allow aliases" do
    class Cmd < Command
      alias_subcommand :list => :default
    end
    
    cmd = Cmd.new(["list"])
    cmd.subcommand.should == :default
  end
end
