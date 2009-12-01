module StackFu
  class ListCommand < Command
    include ApiHooks
  
    def default(parameters, options)
      initialize_api($config)
      user = User.find(:all).first
      items = spinner { 
        [
          Stack.find(:all, :conditions => { "user.id" => user.id }), 
          Plugin.find(:all, :conditions => { "user.id" => user.id })
        ].flatten
      }
      
      params = {
        :class => [Stack, Plugin], 
        :collection => items,
        :display => [:name, :type, :description],
        :main_column => :name,
        :empty => "You have nothing to list yet. To generate stacks or plugins, try the 'stackfu generate' command.",
        :ansi => options[:plain].nil?
      }

      puts table(params) { |item| [item.name, item.class.name.demodulize.downcase, item.description.try(:truncate_words)] }
    end
  end
end