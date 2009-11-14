class Command
  attr_accessor :subcommand, :parameters, :options
  
  class << self
    def create(command, args=[])
      Kernel.const_get("#{command.camelize}Command").new(args)
    end
  end

  def self.inherited(kls)
    def kls.alias_subcommand(spec)
      (@aliases ||= {}).merge!(spec)
    end
    
    def kls.resolve(subcommand)
      (@aliases ||= {})[subcommand.to_sym] or subcommand.to_sym
    end
  end
    
  def initialize(args)
    parse_options(args.reverse)
  end
    
  def run
    send subcommand, parameters, options
  end
  
  private 
  
  def parse_options(args)
    @subcommand = args.pop unless args.last =~ /^-(.*)/
    @subcommand ||=  "default"
    @parameters = []
    @options = {}

    while args.any?
      item = args.pop
      
      if item =~ /^--(.*)/
        parts = $1.split("=")
        name = parts.delete_at(0)
        if parts.any?
          value = parts.first 
        else
          value = true
        end
        @options[name.to_sym] = value
      else
        @parameters << item
      end
    end

    @subcommand = self.class.send(:resolve, @subcommand)
  end
end