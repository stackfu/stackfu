module StackFu::Commands
  class PublishCommand < Command
    include StackFu::ApiHooks
    aliases :pub
    
    def stack?
      File.exists?("stack.yml")
    end
    
    def plugin?
      File.exists?("plugin.yml")
    end

    def default(parameters, options)
      what = :script
      
      unless what
        error "Couldn't find an item to publish on current folder.",
          "Make sure you have a file named 'stack.yml', 'plugin.yml' or use 'stackfu generate' for creating a new stack."
      end
      
      begin
        stack_spec = YAML.load(read("#{what}.yml"))
      
        %w[controls requirements executions validations].each_with_index do |item, i|
          if (yaml = read("config/0#{i+1}-#{item}.yml"))
            yaml.gsub!("type:", "_type:")
            if (from_yaml = YAML.load(yaml))
              if item == 'requirements' or item == 'validations'
                buffer = []
                from_yaml[item].each do |itm|
                  itm["params"] = { "data" => itm.delete("data") }
                  buffer << itm
                end
                from_yaml[item] = buffer
              end
              
              stack_spec[item == "scripts" ? "executions" : item] = from_yaml[item]
            end
          end
        end
        
        unless stack_spec["executions"].present?
          error "To publish a #{what} you have to define at least one execution.",
            "Take a look at the executions descriptor file config/03-executions.yml for more information.\nYou can also use 'stackfu generate stack_name script_name:script' command to auto-generate a sample execution."
          return false
        end
      
        return unless stack_spec["executions"].each do |script|
          template = "executables/#{script["file"]}.sh.erb"
        
          begin
            script["body"] = read(template)
          rescue Errno::ENOENT
            error "The template file for the script '#{script["description"]}' was not found.", "This script has an executable called '#{script["description"]}', and the template for it should be in a file called executables/#{script["file"]}.sh.erb."
            break false
          end
        
          true
        end
        
        item_class = StackFu::ApiHooks.const_get("#{what.to_s.classify}")
        item_class.format = :json

        begin
          stack = item_class.find(stack_spec["name"])
        rescue ActiveResource::ResourceNotFound 
        end

        if stack
          unless options[:update]
            if agree("You already have a #{what} named #{stack_spec["name"]}. Do you want to update it?")
              puts ""
              puts "Tip: Next time you can avoid this question using 'stack pub --update'."
              puts ""
            else
              puts "Aborted."
              return false
            end
          end
        
          begin
            item_class.delete(stack.name)
          rescue ActiveResource::ResourceNotFound 
            puts "There was a problem updating your #{what}. Please report this problem at support@stackfu.com or try again in a few minutes."
            return
          end
        end
      
        puts "Publishing #{what} #{stack_spec["name"]}..."

        stack = item_class.new(stack_spec)

        if publish(stack)
          done "#{what.to_s.titleize} #{stack.name} published."
        else
          error "Could not publish your stack: #{stack.errors.full_messages.to_s}"
        end
      rescue ActiveResource::ServerError
        error "#{$!.message}"
      rescue Errno::ENOENT
        error "There was an error opening your file descriptor"
        raise
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
end