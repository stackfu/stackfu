class HelpCommand < Command
  def default(parameters, options)
    stackfu = "stackfu".foreground(:green).bright
    
    puts "#{"StackFu #{StackFu::VERSION}".foreground(:green).bright}, a server deployment manager."
    puts " (c) 2009-2020 StackFu - http://stackfu.com"
    puts ""
    puts "  Usage:"
    puts "    #{stackfu} #{"command".foreground(:cyan)} [arguments...] [options...]"
    puts ""
    puts "  Examples:"
    puts "    #{stackfu} #{"generate".foreground(:cyan)} stack lamp"
    puts "    #{stackfu} #{"pub".foreground(:cyan)}"
    puts "    #{stackfu} #{"clone".foreground(:cyan)} fcoury lamp"
    puts ""
    puts "  Commands:"
    puts "    #{"help".foreground(:cyan)}                         you already know about this one, dontcha?"
    puts "    #{"config".foreground(:cyan)}                       configure StackFu CLI options"
    puts "    #{"generate".foreground(:cyan)} [stack|plugin]      creates a new stack or plugin in current_dir/name"
    puts "    #{"pub".foreground(:cyan)}                          publishes the item on the current folder to StackFu.com"
    puts "    #{"server".foreground(:cyan)}                       you already know about this one, dontcha?"
    puts "" 
    puts "  For a complete guide on using StackFu from command line:"
    puts "    #{"http://stackfu.com/guides/stackfu-cli".underline}"
  end
end