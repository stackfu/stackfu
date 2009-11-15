class App
  attr_accessor :args
  
  def initialize(args)
    @args = args
  end
  
  def start
    welcome and return unless App.settings?
    $config = load_config
    execute
  end
  
  def execute
    begin
      cmd = Command.create(@args.delete_at(0), @args)
      cmd.run
    rescue Exceptions::InvalidCommand
      puts "Error: #{$!.message}"
    end
  end
  
  def welcome
    puts "== StackFu Initial Configuration ==".bright.color(:green)
    puts ""
    puts "It seems this is the first time you use #{"StackFu".foreground(:yellow)} from the command line."
    puts ""
    puts "To get you up to speed, we need you to provide us a couple of configuration settings that will follow."
    puts
    ConfigCommand.new.run
    true
  end
  
  def load_config
    YAML.load(File.read(StackFu::CONFIG_FILE))
  end
  
  def self.settings?
    File.exists?(StackFu::CONFIG_FILE)
  end
end