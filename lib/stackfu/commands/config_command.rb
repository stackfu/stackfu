class ConfigCommand < Command
  def default(parameters, options)
    while true
      login = ask("StackFu Login: ")
      token = ask("StackFu Token: ")
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
  
  private
  
  def save_config(login, token)
    File.open("#{ENV["HOME"]}/.stackfu", "w") do |file|
      YAML.dump({ :login => login, :token => token }, file)
    end
  end
end