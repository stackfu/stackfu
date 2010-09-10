module StackFu
  class App
    include StackFu::Rendering
    include StackFu::ApiHooks
    attr_accessor :args
  
    def initialize(args)
      @args = args
    end
  
    def start
      welcome and return unless App.settings?
      $config = load_config
      initialize_api($config)
      
      execute
    end
  
    def execute
      begin
        command = @args.delete_at(0)
        cmd = Commands::Command.create(command, @args)
        cmd.run
      rescue Errno::ECONNREFUSED
        error "Could not connect to StackFu server.",
          "Please check if your internet connection is active. If you think this problem is not in your end, please report it by emailing support@stackfu.com or try again in a few minutes."
        raise if $dev

      rescue ActiveResource::ClientError
        error "There was an error contacting StackFu backend: #{$!.message}.",
          "Please report this problem at support@stackfu.com or try again in a few minutes."
        raise if $dev
        
      rescue ActiveResource::ServerError
        error "There was an error contacting StackFu backend: #{$!.message}.",
          "Please report this problem at support@stackfu.com or try again in a few minutes."
        raise if $dev

      rescue ActiveResource::UnauthorizedAccess
        error "Access denied for user '#{$config[:login]}'",
          "Please check the credentials provided on file #{ENV['HOME']}/.stackfu and run 'stackfu config' for changing it."
        raise if $dev

      rescue ActiveResource::ResourceNotFound
        error "There was an internal error contacting StackFu backend.",
          "Please report this problem at support@stackfu.com or try again in a few minutes."
        raise if $dev

      rescue Commands::Exceptions::UnknownCommand
        error "Command #{command} does not exist", "Try using 'stackfu help' for a summary of available commands."
        
      rescue Commands::Exceptions::InvalidCommand
        error "Command #{command} is invalid", $!.message
        
      rescue Commands::Exceptions::InvalidSubcommand
        error "Invalid usage for command #{command}", $!.message
      end
    end
  
    def welcome
      puts "== StackFu Initial Configuration ==".bright.color(:green)
      puts ""
      puts "It seems this is the first time you use #{"StackFu".foreground(:yellow)} from the command line."
      puts ""
      puts "To get you up to speed, we need you to provide us a couple of configuration settings that will follow."
      puts
      Commands::ConfigCommand.new.run
      true
    end
  
    def load_config
      YAML.load(File.read(StackFu::CONFIG_FILE))
    end
  
    def self.settings?
      File.exists?(StackFu::CONFIG_FILE)
    end
  end
end