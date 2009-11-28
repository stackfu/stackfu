require File.dirname(__FILE__) + '/../test_helper.rb'

class TestStackfu < Test::Unit::TestCase
  context "starting the app" do
    should "show a user friendly error when cannot connect" do
      Command.expects(:create).raises(Errno::ECONNREFUSED)
      command "list"
      stdout.should =~ /Could not connect to StackFu server./
      stdout.should_not =~ /Connection refused/
    end
    
    should "provide walk through if first run" do
      when_asked "StackFu Login: ", :answer => "flipper"
      when_asked "StackFu Token: ", :answer => "abc123"
      agree_with "Is this information correct? "
      
      command nil, false
      stdout.should =~ /StackFu Initial Configuration/
    end

    should "provide help if not first run" do
      command nil, true
      stdout.should =~ /StackFu #{StackFu::VERSION}/
      $config.should == { :login => "flipper", :token => "abc123" }
    end
  end
end
