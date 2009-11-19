require File.dirname(__FILE__) + '/../test_helper.rb'

class TestArray < Test::Unit::TestCase
  should "delete correctly with delete_first" do
    arr = ["a","v","a"]
    arr2 = [{ "felipe" => "yes" }, { "others" => "no" }]
    
    arr.delete_first("z").should == nil
    arr.delete_first("a").should == "a"
    arr.should == ["v", "a"]
    
    arr.delete_first {|i| i == "a"}.should == "a"
    arr.should == ["v"]
    
    arr2.delete_first { |i| i.keys.first == "felipe" }.values.first.should == "yes"
  end
  
  should "transform into a struct using to_struct" do
    structs = [{"name" => "Felipe", "id" => "1"},{:name => "Pablo", :id => 2}].to_structs
    
    structs.first.name.should == "Felipe"
    structs.first.id.should == "1"
    structs.last.name.should == "Pablo"
    structs.last.id.should == 2
  end
end