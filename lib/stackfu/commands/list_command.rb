class ListCommand < Command
  include ApiHooks
  include Rendering
  
  def default(parameters, options)
    initialize_api($config)
    user = User.find(:all).first
    params = {
      :class => Stack, 
      :collection => Stack.find(:all, :conditions => { "user.id" => user.id }), 
      :display => [:type, :name],
      :empty => "You have nothing to list yet. To generate stacks or plugins, try the 'stackfu generate' command."
    }

    puts table(params) { |item| ['stack', item.name] }
  end
end