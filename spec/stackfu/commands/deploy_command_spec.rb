# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'spec_helper')

describe StackFu::Commands::DeployCommand do
  it "presents the options when none given" do
    command "deploy" 
    stdout.should =~ /You have to tell which script you want to deploy and to which server./
  end
  
  it "deploys a server" do
    prepare(:get, '/servers/webbynode.json')
    prepare(:get, '/scripts/firewall.json')
    prepare(:post, '/servers/webbynode/deploy.json')

    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json', '/deployments/logs.json')
    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json?from=4c866bb17d7c4261a3000104',
      '/deployments/logs_middle.json')
    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json?from=4c866bb17d7c4261a3000105',
      '/deployments/logs_end.json')
    
    when_asked "  Ports: ", :answer => "80,23,22"

    agree_with "Continue with script installation?\n"

    command "deploy firewall webbynode"
    
    stdout.should =~ /Preparing: firewall/
    stdout.should =~ /Set up a firewall for your server to improve security./
    stdout.should =~ /\*\*\*\* THIS IS THE BEGINNING OF THIS DEPLOYMENT, DUDE! \*\*\*\*/
    stdout.should =~ /-Making the middle-/
    stdout.should =~ /Success/
  end
  
  it "asks no params when script has none" do
    prepare(:get, '/servers/webbynode.json')
    prepare(:get, '/scripts/mongo.json')
    prepare(:post, '/servers/webbynode/deploy.json')

    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json', '/deployments/logs.json')
    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json?from=4c866bb17d7c4261a3000104',
      '/deployments/logs_middle.json')
    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json?from=4c866bb17d7c4261a3000105',
      '/deployments/logs_end.json')
    
    agree_with "Continue with script installation?\n"

    command "deploy mongo webbynode"
    
    stdout.should =~ /Preparing: mongo/
    stdout.should =~ /Installs MongoDB on Ubuntu 10.04/
    stdout.should =~ /\*\*\*\* THIS IS THE BEGINNING OF THIS DEPLOYMENT, DUDE! \*\*\*\*/
    stdout.should =~ /-Making the middle-/
    stdout.should =~ /Success/
  end
  
  it "reports an installation failure" do
    prepare(:get, '/servers/webbynode.json')
    prepare(:get, '/scripts/firewall.json')
    prepare(:post, '/servers/webbynode/deploy.json')

    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json', '/deployments/logs.json')
    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json?from=4c866bb17d7c4261a3000104',
      '/deployments/logs_middle.json')
    prepare(:get, '/deployments/4c82bbb3d489e856ce000006/logs.json?from=4c866bb17d7c4261a3000105',
      '/deployments/logs_failed.json')
    
    when_asked "  Ports: ", :answer => "80,23,22"

    agree_with "Continue with script installation?\n"

    command "deploy firewall webbynode"
    
    stdout.should =~ /Preparing: firewall/
    stdout.should =~ /Set up a firewall for your server to improve security./
    stdout.should =~ /\*\*\*\* THIS IS THE BEGINNING OF THIS DEPLOYMENT, DUDE! \*\*\*\*/
    stdout.should =~ /-Making the middle-/
    stdout.should =~ /Deployment failed/
  end
  
  it "shows an error when the script is not found" do
    prepare(:get, '/scripts/my_script.json', '/scripts/not_found.json')

    command "deploy my_script server"
    stdout.should =~ /Script 'my_script' was not found/
  end

  it "shows an error when script found but server not found" do
    prepare(:get, '/scripts/firewall.json', '/scripts/firewall.json')
    prepare(:get, '/servers/slicey.json', '/servers/not_found.json')

    command "deploy firewall slicey"
    stdout.should =~ /Server 'slicey' was not found/
  end

  it "tells the user if there's a problem submitting the deployment" do
    prepare(:get, '/scripts/firewall.json')
    prepare(:get, '/servers/webbynode.json')
    prepare_raise(:post, '/servers/webbynode/deploy.json', Errno::ECONNREFUSED)

    when_asked "  Ports: ", :answer => "20,21,22"
    
    agree_with "Continue with script installation?\n"

    command "deploy firewall webbynode"
    stdout.should =~ /Could not connect to StackFu server./
  end
  
  it "stops deploying if user disagree of continue prompt" do
    prepare(:get, '/scripts/firewall.json')
    prepare(:get, '/servers/webbynode.json')

    when_asked "  Ports: ", :answer => "20,21,22"
    
    disagree_of "Continue with script installation?\n"

    command "deploy firewall webbynode"
    stdout.should =~ /Aborted./
  end
  
end
