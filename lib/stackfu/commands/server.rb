require 'activeresource'

class ServerCommand < Command
  alias_subcommand :list => :default
  
  class Server < ActiveResource::Base
    self.site = "https://api.stackfu.com"
    self.format = :json
  end
  
  def default(parameters, options)
    servers = Server.find(:all)
    if servers.any?
    else
      puts "You have no servers under your account. Try adding some with 'server add' command."
    end
  end

  def add(parameters, options)
    unless agree("Do you want to add your credentials now?")
      puts "Aborted."
      return
    end

    puts ""
    api_password = ask(<<-EOS)
Enter your Slicehost API password (or type 'help' for more information or 'abort' to abort):
EOS
  end
end