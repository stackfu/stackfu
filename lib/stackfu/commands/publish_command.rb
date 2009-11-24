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