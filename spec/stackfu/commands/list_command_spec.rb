# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::ListCommand do
  it "tells the user if no scripts were found" do
    prepare(:get, '/scripts.json', 'scripts/none.json')
    command "list"
    
    stdout.should =~ /You have nothing to list yet. To generate a new script, use the 'stackfu generate' command/
  end
  
  it "lists plugins" do
    prepare(:get, '/scripts.json', 'scripts/all.json')
    command "list"
    
    stdout.should =~ /Listing 4 scripts/
    stdout.should =~ /firewall/
    stdout.should =~ /mongodb/
    stdout.should =~ /memcached/
    stdout.should =~ /mysql/
  end
end
