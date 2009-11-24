class PublishCommand < Command
  include ApiHooks
  aliases :pub

  def default(parameters, options)
    initialize_api($config)
    begin
      stack_spec = YAML.load(read("stack.yml"))
      
      %w[controls requirements scripts validations].each_with_index do |item, i|
        if (yaml = read("config/0#{i+1}-#{item}.yml"))
          yaml.gsub!("type:", "_type:") if item == "controls"
          if (from_yaml = YAML.load(yaml))
            stack_spec[item == "scripts" ? "executions" : item] = from_yaml[item]
          end
        end
      end
      
      unless stack_spec["executions"].present?
        error "To publish a stack you have to define at least one script.",
          "Take a look at the scripts descriptor file config/03-script.yml for more information.\nYou can also use 'stackfu generate stack_name script_name:script' command to auto-generate a sample script."
        return false
      end
      
      return unless stack_spec["executions"].each do |script|
        template = "script/#{script["file"]}.sh.erb"
        
        begin
          script["data"] = read(template)
        rescue Errno::ENOENT
          error "The template file for the script '#{script["description"]}' was not found.", "This stack has a script called '#{script["description"]}', and the template for it should be in a file called script/#{script["file"]}.sh.erb."
          break false
        end
        
        true
      end

      stacks = Stack.find(:all, :params => { :stack => { :name => stack_spec["name"] } })
      if stacks.any? 
        unless options[:update]
          if agree("You already have a stack named my_stack. Do you want to update it?")
            puts ""
            puts "Tip: Next time you can avoid this question using 'stack pub --update'."
            puts ""
          else
            puts "Aborted."
            return false
          end
        end
        
        stack = stacks.first
        begin
          Stack.delete(stack.id)
        rescue ActiveResource::ResourceNotFound 
          puts "There was a problem updating your stack. Please report this problem at support@stackfu.com or try again in a few minutes."
          return
        end
      end
      
      puts "Publishing stack #{stack_spec["name"]}..."

      stack = Stack.new(stack_spec)
      if publish(stack)
        done "Stack #{stack.name} published."
      else
        error "Could not publish your stack: #{stack.errors.full_messages.to_s}"
      end
    rescue ActiveResource::ServerError
      error "#{$!.message}"
    rescue Errno::ENOENT
      error "Couldn't find a stack on current folder.",
        "Make sure you have a file named 'stack.yml' or use 'stackfu generate' for creating a new stack."
    end
  end
  
  private
  
  def publish(stack)
    spinner {
      stack.save
    }
  end
  
  def read(file)
    File.open(file, "r").readlines.join("")
  end
  
  def load_stack
  end
end