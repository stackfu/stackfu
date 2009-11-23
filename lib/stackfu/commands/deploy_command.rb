class DeployCommand < Command
  include ApiHooks
  
  subcommand :stack, :required_parameters => [:stack_name, :server]
  error_messages :missing_subcommand => "You have to tell what you want to deploy (a stack or a plugin) and to which server."

  def stack(parameters, options)
    initialize_api($config)

    stack_name = parameters[0]
    server_name = parameters[1]

    stacks = Stack.find(:all, :params => { :stack => { :name => stack_name } })
    unless stacks.any?
      error "Stack '#{stack_name}' was not found.",
        "You can create a new stack using 'stackfu generate' or list your current stacks with 'stackfu list'."
      return
    end
    
    server = Server.find(:all, :params => { :server => { :hostname => server_name } })
    unless server.any?
      error "Server '#{server_name}' was not found.",
        "You can add servers 'stackfu server add' or list your current servers with 'stackfu servers'."
      return
    end
    
    stack = stacks.first
    puts "*** Deploying: #{stack.name.foreground(:yellow).bright} (#{OperatingSystems.os_name(stack.operating_system.to_sym).foreground(:yellow)})"
    puts "    #{stack.description}"
    puts ""
    
    if stack.controls.any?
      puts "Please configure your deployment by answering the configuration settings below."
      puts ""

      params = render_stack(stack, options)
    end
    
    puts ""
    unless agree("This will destroy current contents of your server. Are you sure?\n")
      puts "Aborted."
      return false
    end
    
    deployment = Deployment.new(:stack => stack, :server => server.first, :params => params)
    unless deployment.save
      error "There was a problem submitting your deployment: #{deployment.errors.full_messages.to_s}"
      return
    end
    
    puts "Your deployment have been submitted"
  end
end