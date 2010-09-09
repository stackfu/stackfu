# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::ListCommand do
  it "tells the user if no scripts were found" do
    prepare(:get, '/scripts.json', 'scripts/none.json')
    prepare(:get, '/servers.json', 'servers/none.json')
    command "list"
    
    stdout.should =~ /You have nothing to list yet. To generate a new script, use the 'stackfu generate' command/
  end
  
  it "lists scripts" do
    prepare(:get, '/scripts.json', 'scripts/all.json')
    prepare(:get, '/servers.json', 'servers/none.json')
    command "list scripts"
    
    stdout.should =~ /Listing 4 scripts/
    stdout.should =~ /firewall/
    stdout.should =~ /mongodb/
    stdout.should =~ /memcached/
    stdout.should =~ /mysql/
  end
  
  it "lists servers" do
    prepare(:get, '/scripts.json', 'scripts/none.json')
    prepare(:get, '/servers.json', 'servers/all.json')
    command "list servers"

    stdout.should =~ /Listing 2 servers/
    stdout.should =~ /webbynode/
    stdout.should =~ /mydog/
  end
  
  it "lists both" do
    prepare(:get, '/servers.json', 'servers/all.json')
    prepare(:get, '/scripts.json', 'scripts/all.json')

    command "list"
    
    stdout.should =~ /Listing 4 scripts/
    stdout.should =~ /firewall/
    stdout.should =~ /mongodb/
    stdout.should =~ /memcached/
    stdout.should =~ /mysql/

    stdout.should =~ /Listing 2 servers/
    stdout.should =~ /webbynode/
    stdout.should =~ /mydog/
    stdout.should =~ /123.45.678.90/
    stdout.should =~ /123.45.678.91/
  end
end
