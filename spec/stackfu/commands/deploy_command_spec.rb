# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::DeployCommand do
  it "presents the options when none given" do
    command "deploy" 
    stdout.should =~ /You have to tell what you want to deploy and to which server/
  end
  
  it "deploys a server" do
    prepare(:get, '/servers/webbynode.json')
    prepare(:get, '/scripts/firewall.json')
    prepare(:post, '/servers/webbynode/deploy.json')
    
    when_asked "  Ports: ", :answer => "80,23,22"

    agree_with "Continue with script installation?\n"

    command "deploy script firewall webbynode"
    puts stdout
  end
end
