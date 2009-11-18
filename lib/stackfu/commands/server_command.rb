class ServerCommand < Command
  include ApiHooks
  aliases :servers
  
  alias_subcommand :list => :default
  subcommand :add, :required_parameters => [:provider, :server_name]
  subcommand :delete, :required_parameters => [:server_name]

  def default(parameters, options)
    initialize_api($config)
    servers = spinner {
      Server.find(:all)
    }
    if servers.any?
      size = servers.size

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
    # TODO more than one server with the same hostname
    spinner {
      server = Server.find(:all).select { |s| s.hostname == parameters[0] }.first
      server.destroy
    }
    
    puts "Server #{parameters[0]} deleted successfully"
  end

  def add(parameters, options)
    initialize_api($config)
    user = User.find(:all).first
    
    unless user.settings.respond_to?(:slicehost_token)
      return unless add_credentials(user)
    end
    
    result = spinner {
      server = Server.new(:provider_class => parameters[0], :hostname => parameters[1])
      server.provider_class = parameters[0]
      server.hostname = parameters[1]
      server.save
    }
    
    if result
      puts "Server #{parameters.second} added successfully"
    else
      puts "Server #{parameters.second} couldn't be added. Here's the error we've got: #{server.errors.full_messages.to_s}"
    end
  end
  
  private
  
  def add_credentials(user)
    while true
      puts ""
      puts "Enter your Slicehost API password (or type 'help' for more information or 'abort' to abort): "

      token = ask("")
    
      unless ['help', 'abort'].include? token.downcase
        user.settings.slicehost_token = token
        if user.save
          puts ""
          puts "Slicehost credentials saved."
        else
          puts "Error: #{user.errors.full_messages.to_s}"
        end
        return true
      end
      
      if token.downcase == 'abort'
        puts ""
        puts "Aborted adding server."
        return false
      else
        puts ""
        puts "== Slicehost StackFu integration ==".foreground(:green).bright
        puts ""
        puts "In order to allow StackFu to integrate itself with Slicehost, you need to enabled your API Access and provide us your API Password."
        puts ""
        puts "This can be easily done by visiting your '#{"Account > API Access".foreground(:cyan)}' area in Slicehost manager."
        puts ""
        puts "If you need further information, visit #{"http://stackfu.com/faq/slicehost-api-integration".underline} for a complete walkthrough of this process."
      end
    end
  end
end