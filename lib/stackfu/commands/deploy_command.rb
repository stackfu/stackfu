module StackFu
  class DeployCommand < Command
    include ApiHooks
  
    error_messages :missing_subcommand => "You have to tell what you want to deploy (a stack or a plugin) and to which server."

    subcommand :plugin, :required_parameters => [:plugin_name, :server]
    subcommand :stack,  :required_parameters => [:stack_name, :server]

    def plugin(parameters, options)
      execute "plugin", parameters, options, false do |target|
        puts "*** Preparing: #{target.name.foreground(:yellow).bright}"
        puts "    #{target.description}"
        puts ""
      end
    end
    
    def stack(parameters, options)
      execute "stack", parameters, options, true do |target|
        puts "*** Deploying: #{target.name.foreground(:yellow).bright} (based on #{os_name(target.operating_system.to_sym).foreground(:yellow)})"
        puts "    #{target.description}"
        puts ""
      end
    end

    private
    
    def extract_settings(target)
      target_name = parameters[0]
      server_name = parameters[1]      
      
      target_class = StackFu::ApiHooks.const_get(target.capitalize)
      
      targets = target_class.find(:all, :params => { target.to_sym => { :name => target_name } })
      unless targets.any?
        error "#{target.capitalize} '#{target_name}' was not found"
        return
      end
      
      server = Server.find(:all, :params => { :server => { :hostname => server_name } })
      unless server.any?
        error "Server '#{server_name}' was not found.",
          "You can add servers 'stackfu server add' or list your current servers with 'stackfu servers'."
        return
      end
      
      return targets.first, server
    end
    
    def execute(target_name, parameters, options, stack)
      target, server = extract_settings(target_name)
      return unless target
      
      yield target
      
      params = fill_values_from_options(target, options)
      names = target.controls.map(&:name)
      review = params.any?
      
      if (names - params.keys.map(&:to_s)).any?
        puts "Please configure your deployment by answering the configuration settings below."
        puts ""

        params = render_target(params, target, options)
        
        puts ""
      end
      
      # We'll only show a review if > 1 item was not collected from console
      if review
        max_length = target.controls.map { |c| c.label.size }.max
        
        puts "Please review the configuration for your deployment:"
        puts ""
        target.controls.each do |c|
          puts "  #{c.label.rjust(max_length).foreground(:yellow)}#{":".foreground(:yellow)} #{params[c.name]}"
        end
        puts ""
      end
    
      if stack
        unless warning("This will destroy current contents of your server. Are you sure?\n")
          puts "Aborted."
          return false
        end
      end
    
      item = target if stack
      hash = { :stack => item, :server_id => server.first.id, :params => params }
      
      unless stack
        hash[:plugin_ids] = [target.id]
      end
      
      deployment = Deployment.new(hash)
      
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