module StackFu::Commands
  class HelpCommand < Command
    def default(parameters, options)
      stackfu = "stackfu".foreground(:green).bright
    
      puts "#{"StackFu #{StackFu::VERSION}".foreground(:green).bright} - social server provisioning."
      puts " (c) 2010-2020 StackFu - http://stackfu.com"
      puts ""
      puts "  Usage:"
      puts "    #{stackfu} #{"command".foreground(:cyan)} [arguments...] [options...]"
      puts ""
      puts "  Examples:"
      puts "    #{stackfu} #{"generate".foreground(:cyan)} lamp"
      puts "    #{stackfu} #{"pub".foreground(:cyan)}"
      puts "    #{stackfu} #{"deploy".foreground(:cyan)} lamp server1"
      puts ""
      puts "  Commands:"
      puts "    #{"help".foreground(:cyan)}                         you already know about this one, dontcha?"
      puts "    #{"config".foreground(:cyan)}                       configure StackFu CLI options"
      puts "    #{"list".foreground(:cyan)} [servers|script]        lists all the scripts and/or server under your account"
      puts "    #{"generate".foreground(:cyan)}                     creates a new script in current_dir/name"
      puts "    #{"publish".foreground(:cyan)}                      publishes the item on the current folder to StackFu.com"
      puts "" 
      puts "  For a complete guide on using StackFu from command line:"
      puts "    #{"http://stackfu.com/guides/stackfu-cli".underline}"
    end
  end
end