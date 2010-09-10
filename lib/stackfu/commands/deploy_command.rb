module StackFu::Commands
  class DeployCommand < Command
    include StackFu::ApiHooks
  
    # error_messages :missing_subcommand => "You have to tell what you want to deploy and to which server."
    # subcommand :script, :required_parameters => [:plugin_name, :server]

    def default(parameters, options)
      execute "script", parameters, options, false do |target|
        puts "*** Preparing: #{target.name.foreground(:yellow).bright}"
        puts "    #{target.description}"
        puts ""
      end
    end

    private
    
    def extract_settings(target)
      target_name = parameters[0]
      server_name = parameters[1]      
      
      target_class = StackFu::ApiHooks.const_get(target.capitalize)
      begin
        target = target_class.find(target_name)
      rescue ActiveResource::ResourceNotFound
        error "#{target.capitalize} '#{target_name}' was not found"
        return
      end

      begin
        target = target_class.find(target_name)
      rescue ActiveResource::ResourceNotFound
        error "#{target.capitalize} '#{target_name}' was not found"
        return
      end

      unless target
        error "#{target.capitalize} '#{target_name}' was not found"
        return
      end
      
      begin
        server = Server.find(server_name)
      rescue ActiveResource::ResourceNotFound
        error "Server '#{server_name}' was not found"
        return
      end
      
      return target, server
    end
    
    def execute(target_name, parameters, options, stack)
      if parameters.size < 2
        puts "You have to tell which script you want to deploy and to which server."
        puts "Usage: stackfu deploy [script] [server]"
        return
      end
      
      target, server = extract_settings(target_name)
      return unless target and server
      
      yield target
      
      params = fill_values_from_options(target, options)
      names = target.controls ? target.controls.map(&:name) : []
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
    
      unless agree "Continue with script installation?\n"
        puts "Aborted."
        return false
      end
      
      server_id = server.id
      server.id = server.slug
      begin
        deployment = server.post(:deploy, {}, { :id => server_id, :script_id => target.slug, :params => params }.to_json)
      rescue ActiveResource::ClientError
        if $!.message =~ /406/
          puts "Error: ".foreground(:red) + "Cannot deploy - there is another deploy queued or running for this server."
          return
        else
          raise
        end
      end
        
      deployment = JSON.parse(deployment.body)
      
      if options[:"no-follow"]
        puts "Your deployment have been submitted"
        return 
      end
      
      puts ""
      puts "Waiting for the server..."
    
      verbose = options[:verbose]
    
      from = nil
      last_status = 'queued'
      finished = false
      
      while true
        opts = {} 
        opts['from_id'] = from if from
      
        logs = spinner {
          Deployment.new(:id => deployment['_id']).get(:logs, opts)
        }

        status = logs['status']
        if status != last_status
          if status == 'running'
            puts ""
            puts "---------- " + " SCRIPT STARTED ".foreground(:white).bright.background(:blue) + " ----------"
            puts ""
          elsif status == 'finished'
            finished = true
          end
          last_status = status
        end
        
        from = logs["last_id"] 
        print logs["contents"]
        
        if finished
          puts ""
          puts "---------- " + " SCRIPT FINISHED ".foreground(:white).bright.background(:blue) + " ----------"
        end
        
        break if logs["status"] == "finished" or logs["status"] == "failed"
      end
      
      puts ""

      if logs["status"] == 'finished'
        puts "Deployment finished: " + " SUCCESS ".foreground(:white).bright.background(:green)
      else
        puts "Deployment failed".foreground(:red)
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