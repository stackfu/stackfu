class App
  attr_accessor :args
  
  def initialize(*args)
    @args = args
  end
  
  def start
    welcome and return unless App.settings?
    execute
  end
  
  def execute
    cmd = Command.create(@args.delete_at(0), @args)
    cmd.run
  end
  
  def welcome
    puts "== StackFu Initial Configuration ==".bright.color(:green)
    puts ""
    puts "It seems this is the first time you use #{"StackFu".foreground(:yellow)} from the command line."
    puts ""
    puts "To get you up to speed, we need you to provide us a couple of configuration settings that will follow."
    puts
    true
  end
  
  def self.settings?
    File.exists?("#{ENV['HOME']}/.stackfu")
  end
end