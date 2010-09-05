module StackFu::Commands
  class ListCommand < Command
    include StackFu::ApiHooks
  
    def default(parameters, options)
      # user = User.find(:all).first
      items = spinner { 
        [
          Script.find(:all)
        ].flatten
      }
      
      params = {
        # :class => [Stack, Plugin], 
        :class => [Script], 
        :collection => items,
        :display => [:name, :type, :description],
        :main_column => :name,
        :empty => "You have nothing to list yet. To generate a new script, use the 'stackfu generate' command.",
        :ansi => options[:plain].nil?
      }

      puts table(params) { |item| 
        description = item.respond_to?(:description) ? item.description : ""
        
        [item.name, "Script", description.truncate_words(10)]
      }
    end
  end
end