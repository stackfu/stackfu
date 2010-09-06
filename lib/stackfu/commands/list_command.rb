module StackFu::Commands
  class ListCommand < Command
    include StackFu::ApiHooks
  
    # error_messages :missing_subcommand => "You have to tell what you want to deploy and to which server."

    subcommand :servers, :required_parameters => []
    subcommand :scripts, :required_parameters => []
    
    def servers(parameters, options)
      list [Server], "You have no servers yet. You can add new servers to your account in http://stackfu.com."
    end
    
    def scripts(parameters, options)
      list [Script], ["You have nothing to list yet. To generate a new script, use the 'stackfu generate' command."]
    end
    
    def default(parameters, options)
      list [Script, Server], 
        ["You have no scripts yet. To generate a new script, use the 'stackfu generate' command.\n",
         "You have no servers yet. You can add new servers to your account in http://stackfu.com.\n"]
    end
    
    private

    def list(things_to_list, errors_when_empty)
      things_to_list.each_with_index do |t, i|
        kls = t
        
        items = spinner { 
          [
            kls.find(:all)
          ].flatten
        }
      
        params = {
          :class => [kls], 
          :collection => items,
          :display => [:name, :type, :description],
          :main_column => :name,
          :empty => errors_when_empty[i],
          :ansi => options[:plain].nil?
        }

        puts table(params) { |item| 
          description = item.respond_to?(:description) ? item.description : ""
        
          [item.name, kls.name.split('::').last, description.truncate_words(10)]
        }
        
        puts "" if i < things_to_list.size-1
      end
    end
  end
end