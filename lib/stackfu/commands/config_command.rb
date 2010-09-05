module StackFu::Commands
  class ConfigCommand < Command
    include StackFu::ApiHooks
    include StackFu::ProvidersCredentials
    
    def default(parameters, options)
      while true
        login = options[:login] || ask("StackFu Login: ")
        token = options[:token] || ask("StackFu Token: ")
      
        break if options[:login] and options[:token]
        
        puts ""
        break if agree("Is this information correct? ", true)
        puts ""
        puts "OK, let's try it again"
        puts ""
      end
    
      puts ""
      puts "Configuration saved to #{ENV['HOME']}/.stackfu"
      save_config(login, token)
    end
    
    def webbynode(parameters, options)
      user = spinner { User.find(:all).first }
      add_webbynode_credentials(user)
    end
  
    def slicehost(parameters, options)
      user = spinner { User.find(:all).first }
      add_slicehost_credentials(user)
    end
  
    private
  
    def save_config(login, token)
      File.open("#{ENV["HOME"]}/.stackfu", "w") do |file|
        YAML.dump({ :login => login, :token => token }, file)
      end
    end
  end
end