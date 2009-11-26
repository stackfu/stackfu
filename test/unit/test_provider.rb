require File.dirname(__FILE__) + '/../test_helper.rb'

class TestProvider < Test::Unit::TestCase
  include StackFu::ApiHooks
  
  should "provide a list with provider names and codes" do
    with_providers
    
    providers = Provider.find(:all)
    providers.select { |p| p.id == "webbynode" }.size.should == 1
    providers.select { |p| p.id == "slicehost" }.size.should == 1
    providers.select { |p| p.id == "linode" }.size.should == 1
  end
end