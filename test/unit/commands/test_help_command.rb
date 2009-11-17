require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestHelpCommand < Test::Unit::TestCase
  context "creating" do
    should "show default help message if no subcommand was given" do
      stackfu = "stackfu".foreground(:green).bright

      cmd = HelpCommand.new([])
      cmd.expects(:puts).with "#{"StackFu #{StackFu::VERSION}".foreground(:green).bright}, a server deployment manager."
      cmd.expects(:puts).with " (c) 2009-2020 StackFu - http://stackfu.com"
      cmd.expects(:puts).with ""
      cmd.expects(:puts).with "  Usage:"
      cmd.expects(:puts).with "    #{stackfu} #{"command".foreground(:cyan)} [arguments...] [options...]"
      cmd.expects(:puts).with ""
      cmd.expects(:puts).with "  Examples:"
      cmd.expects(:puts).with "    #{stackfu} #{"generate".foreground(:cyan)} stack lamp"
      cmd.expects(:puts).with "    #{stackfu} #{"pub".foreground(:cyan)}"
      cmd.expects(:puts).with "    #{stackfu} #{"clone".foreground(:cyan)} fcoury lamp"
      cmd.expects(:puts).with ""
      cmd.expects(:puts).with "  Commands:"
      cmd.expects(:puts).with "    #{"help".foreground(:cyan)}                         you already know about this one, dontcha?"
      cmd.expects(:puts).with "    #{"config".foreground(:cyan)}                       configure StackFu CLI options"
      cmd.expects(:puts).with "    #{"server".foreground(:cyan)}                       create, delete, update and deploy to StackFu servers"
      cmd.expects(:puts).with "    #{"generate".foreground(:cyan)} [stack|plugin]      creates a new stack or plugin in current_dir/name"
      cmd.expects(:puts).with "    #{"pub".foreground(:cyan)}                          publishes the item on the current folder to StackFu.com"
      cmd.expects(:puts).with "" 
      cmd.expects(:puts).with "  For a complete guide on using StackFu from command line:"
      cmd.expects(:puts).with "    #{"http://stackfu.com/guides/stackfu-cli".underline}"
      
      cmd.run
    end
  end
end
