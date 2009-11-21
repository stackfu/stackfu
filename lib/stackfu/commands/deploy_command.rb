class DeployCommand < Command
  include ApiHooks
  
  subcommand :stack, :required_parameters => [:stack_name, :server]
  error_messages :missing_subcommand => "You have to tell what you want to deploy (a stack or a plugin) and to which server."

  def stack(parameters, options)
    initialize_api($config)

    stack_name = parameters[0]
    server_name = parameters[1]
    
    stack = Stack.find(:all, :params => { :stack => { :name => stack_name } })
    unless stack.any?
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
    
    deployment = Deployment.new(:stack_id => stack.first, :server_id => server.first)
    unless deployment.save
      error "/There was a problem submitting your deployment: #{deployment.errors.full_messages.to_s}"
      return
    end
    
    puts "Your deployment have been submitted"
  end
end