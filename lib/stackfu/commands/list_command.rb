module StackFu::Commands
  class ListCommand < Command
    include StackFu::ApiHooks
    
    class << self
      include DateHelper
    end
  
    # error_messages :missing_subcommand => "You have to tell what you want to deploy and to which server."

    subcommand :servers, :required_parameters => []
    subcommand :scripts, :required_parameters => []
    
    TableAttributes = {
      Server => [
        [:name, :key, :ip, :validated, :last_seen],
        lambda do |item| 
          last_seen = item.last_checked_in if item.respond_to?(:last_checked_in)
          
          if last_seen
            last_seen = distance_of_time_in_words(Time.now, Time.parse(last_seen))
            last_seen = "#{last_seen} ago"
          else
            last_seen = "- never -"
          end
          
          validated = item.validated? ? "yes" : ""
          
          [item.name, item._id, item.ip, validated, last_seen]
        end,
        "You have no servers yet. You can add new servers to your account in http://stackfu.com."
      ],
      Script => [
        [:name, :description],
        lambda { |item| [item.name, (item.description || "").truncate_words(10)] },
        "You have nothing to list yet. To generate a new script, use the 'stackfu generate' command."
      ]
    }
    
    def servers(parameters, options)
      list Server
    end
    
    def scripts(parameters, options)
      list Script
    end
    
    def default(parameters, options)
      list [Script, Server]
    end
    
    private

    def list(things_to_list)
      things_to_list = [things_to_list] unless things_to_list.is_a?(Enumerable)
      
      things_to_list.each_with_index do |kls, i|
        attributes = TableAttributes[kls]

        display = attributes[0]
        fields  = attributes[1]
        error   = attributes[2]
        
        items = spinner { 
          [
            kls.find(:all)
          ].flatten
        }
      
        params = {
          :class => [kls], 
          :collection => items,
          :display => display,
          :main_column => :name,
          :empty => error,
          :ansi => options[:plain].nil?
        }

        puts table(params) { |item| fields.call item }
        
        puts "" if i < things_to_list.size-1
      end
    end
  end
end