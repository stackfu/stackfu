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
        return unless stack_spec = read_and_validate(what)
      
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
        rescue NoMethodError
          if $!.message =~ /closed\?/
            raise Errno::ECONNREFUSED
          else
            raise
          end
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
    
    def fmt_error(message)
      result = block_given? ? yield : false
      
      unless result
        error message, "For more information about file formats, check out http://stackfu.com/guides/stackfu-cli."
        return false
      end
      
      true
    end
    
    def read_and_check(yml)
      begin
        return YAML.load(read(yml))
      rescue ArgumentError
        fmt_error "Invalid YAML document in #{yml}. Parse error: #{$!.message}"
        return
      end
    end
    
    def read_and_validate(what)
      return unless stack_spec = read_and_check("#{what}.yml")
      return unless fmt_error("The #{what}.yml descriptor has the wrong format.") { stack_spec.is_a?(Hash) }
      return unless fmt_error("Missing field 'name' in script.yml.")              { stack_spec['name'] }
      return unless fmt_error("Missing field 'type' in script.yml.")              { stack_spec['type'] }    
      return unless fmt_error("Invalid value for field 'type' in script.yml.")    { stack_spec['type'] == 'script' }
      return unless validate_controls
      return unless validate_requirements
      return unless validate_executions
      return unless validate_validations
      
      stack_spec
    end
    
    def validate_spec(idx, name, item_id, checks)
      file = "config/#{idx}-#{name}.yml"
      
      return unless spec = read_and_check(file)
      return unless fmt_error("Invalid format for #{file}.") { 
        spec.is_a?(Hash) && spec[name].is_a?(Array) 
      }
      
      spec[name].each_with_index do |item, i|
        checks.each do |check|
          if item_id.nil? or check == item_id
            return unless fmt_error("missing #{check} for #{name.singularize} #{i+1} in #{file}.") { item[check] }
          else
            return unless fmt_error("missing #{check} for #{name.singularize} '#{item[item_id]}' in #{file}.") { item[check] }
          end
        end
        
        return unless yield(item, i+1) if block_given?
      end
    end
    
    def validate_controls
      return unless validate_spec '01', 'controls', 'name', ['name', 'type'] do |item, i|
        return unless fmt_error("invalid type '#{item["type"]}' for control '#{item["name"]}' in config/01-controls.yml.") { 
          %w(Textbox Numericbox Password).include? item['type']
        }
        true
      end

      true
    end
    
    def validate_requirements
      return unless validate_spec '02', 'requirements', nil, ['type', 'data'] do |item, i|
        return unless fmt_error("invalid type '#{item["type"]}' for requirement #{i} in config/02-requirements.yml.") { 
          %w(DirExists FileExists ExecutableExists ProcessExists RubyCanLoad RubyGem SymlinkExists).include? item['type']
        }
        true
      end
      
      true
    end
  
    def validate_executions
      return unless validate_spec '03', 'executions', 'file', ['file', 'description']
      
      true
    end
    
    def validate_validations
      return unless validate_spec '04', 'validations', nil, ['type', 'data'] do |item, i|
        return unless fmt_error("invalid type '#{item["type"]}' for validation #{i} in config/04-validations.yml.") { 
          %w(DirExists FileExists ExecutableExists ProcessExists RubyCanLoad RubyGem SymlinkExists).include? item['type']
        }
        true
      end
      
      true
    end
        
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