require File.dirname(__FILE__) + '/../test_helper.rb'

class TestStackfu < Test::Unit::TestCase
  context "starting the app" do
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

  context "Array.delete_first" do
    should "delete correctly" do
      arr = ["a","v","a"]
      arr2 = [{ "felipe" => "yes" }, { "others" => "no" }]
      
      arr.delete_first("z").should == nil
      arr.delete_first("a").should == "a"
      arr.should == ["v", "a"]
      
      arr.delete_first {|i| i == "a"}.should == "a"
      arr.should == ["v"]
      
      arr2.delete_first { |i| i.keys.first == "felipe" }.values.first.should == "yes"
    end
  end
end
