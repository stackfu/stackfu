class Command
  attr_accessor :subcommand, :parameters, :options, :errors
  
  class << self
    attr_accessor :aliases
    
    def create(command, args=[])
      command ||= "help"
      klass = aliases[command.to_sym]||Kernel.const_get("#{command.camelize}Command")
      klass.new(args)
    end

    def inherited(kls)
      def kls.aliases(*aliases)
        aliases.each do |a|
          (Command.aliases||={})[a.to_sym] = self
        end
      end
      
      def kls.alias_subcommand(spec)
        (@subcommand_aliases ||= {}).merge!(spec)
      end

      def kls.resolve(subcommand)
        (@subcommand_aliases ||= {})[subcommand.to_sym] or subcommand.to_sym
      end

      def kls.subcommand(name, options)
        (@subcommand_options ||= {})[name.to_sym] = options
      end
      
      def kls.subcommand_options
        @subcommand_options || {}
      end
      
      def kls.error_messages(spec)
        (@error_messages ||= {}).merge!(spec)
      end
      
      def kls.error_for(type)
        (@error_messages ||= {})[type]
      end
    end  
  end
  
  def command
    self.class.name.demodulize.underscore.gsub /_command/, ""
  end
      
  def initialize(args=[])
    @errors = []
    parse_options(args.reverse)
    validate(self.class.subcommand_options[subcommand.to_sym])
  end
  
  def params?
    parameters.any?
  end
    
  def run
    unless self.respond_to?(subcommand)
      error = self.class.error_for(:missing_subcommand)
      error ||= "Command #{command} doesn't have a subcommand \"#{subcommand}\". Try \"stackfu #{command} help\" for more information."
      raise Exceptions::InvalidCommand, error % [subcommand]
    end
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
        error = self.class.error_for(:missing_params)
        error ||= "The command #{command.to_s.foreground(:yellow)} #{subcommand.to_s.foreground(:yellow)} requires #{req.size} parameters.\nUsage: stackfu #{command} #{subcommand} #{req.to_params}" 
        @errors << error
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