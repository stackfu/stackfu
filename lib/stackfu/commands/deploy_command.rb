module StackFu
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
      puts "*** Deploying: #{stack.name.foreground(:yellow).bright} (based on #{os_name(stack.operating_system.to_sym).foreground(:yellow)})"
      puts "    #{stack.description}"
      puts ""
      
      params = fill_values_from_options(stack, options)
      names = stack.controls.map(&:name)
      review = params.any?
      
      if (names - params.keys.map(&:to_s)).any?
        puts "Please configure your deployment by answering the configuration settings below."
        puts ""

        params = render_stack(params, stack, options)
        
        puts ""
      end
      
      # We'll only show a review if > 1 item was not collected from console
      if review
        max_length = stack.controls.map { |c| c.label.size }.max
        
        puts "Please review the configuration for your deployment:"
        puts ""
        stack.controls.each do |c|
          puts "  #{c.label.rjust(max_length).foreground(:yellow)}#{":".foreground(:yellow)} #{params[c.name]}"
        end
        puts ""
      end
    
      unless warning("This will destroy current contents of your server. Are you sure?\n")
        puts "Aborted."
        return false
      end
    
      deployment = Deployment.new(:stack => stack, :server => server.first, :params => params)
      unless deployment.save
        error "There was a problem submitting your deployment: #{deployment.errors.full_messages.to_s}"
        return
      end
    
      if options[:"no-follow"]
        puts "Your deployment have been submitted"
        return 
      end
    
      verbose = options[:verbose]
    
      from = nil
      while true
        opts = {:formatted => "true", :from => from}
        opts.merge!(:verbose => "true") if verbose

        status = spinner {
          Deployment.find(deployment.id).get(:logs, opts)
        }
      
        if status["id"]
          show_log status["log"]
          from = status["id"] 
        end

        break if status["state"] == "finished" or status["state"] == "failed"
      end
    end
  
    private
  
    def show_log(logs)
      logs.each do |s|
        if s =~ /^  \[stdout\]/
          puts s.chop.gsub("  [stdout] ", "").gsub(/^/, "  ").foreground(:yellow)
        elsif s =~ /^  \[stderr\]/
          puts s.chop.gsub("  [stderr] ", "").gsub(/^/, "  ").foreground(:red)
        else
          puts s
        end
      end
    end
  end
end