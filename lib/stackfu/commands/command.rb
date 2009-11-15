class Command
  attr_accessor :subcommand, :parameters, :options, :errors
  
  class << self
    def create(command, args=[])
      command ||= "help"
      Kernel.const_get("#{command.camelize}Command").new(args)
    end

    def inherited(kls)
      def kls.alias_subcommand(spec)
        (@aliases ||= {}).merge!(spec)
      end

      def kls.resolve(subcommand)
        (@aliases ||= {})[subcommand.to_sym] or subcommand.to_sym
      end

      def kls.subcommand(name, options)
        (@subcommand_options ||= {})[name.to_sym] = options
      end
      
      def kls.subcommand_options
        @subcommand_options || {}
      end
    end  
  end
  
  def command
    self.class.name.underscore.gsub /_command/, ""
  end
      
  def initialize(args=[])
    @errors = []
    parse_options(args.reverse)
    validate(self.class.subcommand_options[subcommand.to_sym])
  end
    
  def run
    send subcommand, parameters, options
  end
  
  def valid?
    validate(self.class.subcommand_options[subcommand.to_sym])
  end
  
  private 
  
  def validate(rules)
    return true unless rules
    
    if (req = rules[:required_parameters])
      if parameters.size < req.size
        @errors << "The command #{command.to_s.foreground(:yellow)} #{subcommand.to_s.foreground(:yellow)} requires #{req.size} parameters.\nUsage: stackfu #{command} #{subcommand} #{req.to_params}" 
      end
    end
    
    raise Exceptions::InvalidCommand, @errors.to_phrase unless @errors.empty?
  end
  
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