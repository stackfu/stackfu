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
    end
  end
end