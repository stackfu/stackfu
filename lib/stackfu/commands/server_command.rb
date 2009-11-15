require 'activeresource'

class ServerCommand < Command
  alias_subcommand :list => :default
  subcommand :add, :required_parameters => [:provider, :server_name]
  
  class Server < ActiveResource::Base
    self.format = :json
  end
  
  class User < ActiveResource::Base
    self.format = :json
  end
  
  def initialize(args=[])
    Server.site = StackFu::API.gsub(/api/, "#{$config[:login]}:#{$config[:token]}@api") + "/"
    User.site = StackFu::API.gsub(/api/, "#{$config[:login]}:#{$config[:token]}@api") + "/"
    super
  end
  
  def default(parameters, options)
    servers = Server.find(:all)
    if servers.any?
      size = servers.size
      
      if size < 1
        puts "You have no servers under your account. Try adding some with 'server add' command." 
        return
      end

      puts "You have #{size} server#{size > 1 ? "s" : ""} under your account:"
      puts ""
      puts "  #{"Hostname".underline.foreground(:yellow)}\t#{"Provider".underline.foreground(:yellow)}\t#{"IP".underline.foreground(:yellow)}"

      servers.each do |server|
        puts "  #{server.hostname.foreground(:blue)}\t#{server.provider_class}\t#{server.ip}"
      end
    else
      puts "You have no servers under your account. Try adding some with 'server add' command."
    end
  end
  
  def delete(parameters, options)
    # TODO more than one server
    server = Server.find(:all).select { |s| s.hostname == parameters[0] }.first
    server.destroy
    
    puts "Server #{parameters[0]} deleted successfully"
  end

  def add(parameters, options)
    user = User.find(:all).first
    
    unless user.settings.respond_to?(:slicehost_token)
      return unless add_credentials(user)
    end
    
    puts "Parameters: #{parameters.inspect}"
    server = Server.new(:provider_class => parameters[0], :hostname => parameters[1])
    server.provider_class = parameters[0]
    server.hostname = parameters[1]
    if server.save
      puts "Server #{parameters.second} added successfully"
    else
      puts "Server #{parameters.second} couldn't be added. Here's the error we've got: #{server.errors.full_messages.to_s}"
    end
  end
  
  private
  
  def add_credentials(user)
    unless agree("Do you want to add your credentials now?")
      puts "Aborted."
      return false
    end

    puts ""
    api_password = ask(<<-EOS)
Enter your Slicehost API password (or type 'help' for more information or 'abort' to abort):
EOS

    user.settings.slicehost_token = api_password
    user.save
  end
end