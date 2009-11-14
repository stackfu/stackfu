require File.dirname(__FILE__) + '/../test_helper.rb'

class TestStackfu < Test::Unit::TestCase
  context "starting the app" do
    should "provide walk through if first run" do
      when_asked "StackFu Login: ", :answer => "flipper"
      when_asked "StackFu Token: ", :answer => "abc123"
      
      command "", false
      stdout.should =~ /StackFu Initial Configuration/
    end

    # should "provide help if not first run" do
    #   File.expects(:exists?).with("#{ENV["HOME"]}/.stackfu").returns(true)
    #   
    #   stackfu = App.new
    #   stackfu.expects(:puts).with "help"
    #   
    #   stackfu.start
    # end
    
    # should "parse command if provided" do
    #   File.expects(:exists?).with("#{ENV["HOME"]}/.stackfu").returns(true)
    # 
    #   stackfu = App.new("config")
    #   stackfu.start
    #   stackfu.command.should == "config"
    # end
  end
end
