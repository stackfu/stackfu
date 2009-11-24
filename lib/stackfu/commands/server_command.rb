class ServerCommand < Command
  include ApiHooks

  aliases :servers
  
  alias_subcommand :list => :default
  # subcommand :add, :required_parameters => [:provider, :server_name]
  subcommand :delete, :required_parameters => [:server_name]

  def default(parameters, options)
    initialize_api($config)

    servers = spinner {
      Server.find(:all)
    }

    params = {
      :class => Server, 
      :collection => servers, 
      :display => [:hostname, :provider_class, :ip],
      :labels => { :hostname => "Name", :provider_class => "Provider", :ip => "IP"},
      :main_column => :hostname,
      :empty => "You have no servers under your account. Try adding some with 'server add' command.",
      :ansi => options[:plain].nil?
    }
    
    puts table(params)
  end
  
  def delete(parameters, options)
    initialize_api($config)
    # TODO more than one server with the same hostname
    spinner {
      server = Server.find(:all).select { |s| s.hostname == parameters[0] }.first
      server.destroy
    }
    
    puts "Server #{parameters[0]} deleted successfully"
  end

  def add(parameters, options)
    initialize_api($config)
    
    if params?
      if parameters.size < 2
        puts "The command #{"server add".to_s.foreground(:yellow)} requires 2 parameters.\nUsage: stackfu server add PROVIDER SERVER_NAME"
        return false
      end
      provider = parameters[0]
      server_name = parameters[1]
    else
      server_add_header
    end
    
    user = User.find(:all).first

    unless user.settings.respond_to?(:slicehost_token)
      return unless add_credentials(user)
    end

    unless params?
      provider, server_name = *server_menu
    end
    
    server = Server.new(:provider_class => provider, :hostname => server_name)
    result = spinner {
      server.save
    }
    
    puts " "
    if result
      puts "Server #{server_name} added successfully."
    else
      puts " "
      puts "Server #{server_name} couldn't be added. Here's the error we've got:\n#{server.errors.full_messages.to_s}"
    end
  end
  
  private
  
  def server_add_header
    puts "=== Add Server ===".foreground(:green).bright
  end
  
  def server_menu
    providers = spinner { Provider.find(:all) }
    provider_id = menu_for("provider", providers, true)
    
    provider = providers.select { |p| p.id == provider_id }.first
    
    puts ""
    puts "Provider: #{provider_id.foreground(:blue)}"
    puts ""

    servers = spinner { provider.get(:servers).to_structs }
    server = menu_for("server", servers)
    
    puts ""
    puts "Adding server #{server.foreground(:blue)}..."
    
    [provider_id.titleize, server]
  end
  
  def slicehost
    spinner {
      UserAccount.find(:conditions => { :provider => "Slicehost" }).servers
    }
  end
  
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