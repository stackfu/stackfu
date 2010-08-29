module StackFu
  class ListCommand < Command
    include ApiHooks
  
    def default(parameters, options)
      # user = User.find(:all).first
      items = spinner { 
        [
          # Stack.find(:all, :conditions => { "user.id" => user.id }), 
          Plugin.find(:all)
        ].flatten
      }
      
      params = {
        # :class => [Stack, Plugin], 
        :class => [Plugin], 
        :collection => items,
        :display => [:name, :type, :description],
        :main_column => :name,
        :empty => "You have nothing to list yet. To generate stacks or plugins, try the 'stackfu generate' command.",
        :ansi => options[:plain].nil?
      }

      puts table(params) { |item| 
        description = item.respond_to?(:description) ? item.description : ""
        
        [item.name, "Plugin", description.truncate_words(10)]
      }
    end
  end
end