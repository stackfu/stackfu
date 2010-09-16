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
    
    def format_error
      messages = ["there were validation problems with your script.", ""]
      %w(script.yml config/01-controls.yml config/02-requirements.yml config/03-executions.yml config/04-validations.yml).each do |f|
        if @errors[f]
          messages << "Errors in #{f.foreground(:green)}:"
          messages << @errors[f].map { |e| "- #{e}" }
          messages << ""
        end
      end
      
      messages.flatten.join("\n")
    end

    def default(parameters, options)
      what = :script
      
      unless what
        error "Couldn't find an item to publish on current folder.",
          "Make sure you have a file named 'stack.yml', 'plugin.yml' or use 'stackfu generate' for creating a new stack."
      end
      
      begin
        stack_spec = read_and_validate(what)
        
        if @errors.keys.any?
          error format_error
          return
        end
      
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
    
    def check(file, message)
      return true if result = block_given? ? yield : false
      
      (@errors[file]||=[]) << message.gsub(/'(.*)'/, '\1'.foreground(:blue).bright)
      false
    end
    
    def read_and_check(yml)
      begin
        return YAML.load(read(yml))
      rescue ArgumentError
        (@errors[yml]||=[]) << "invalid YAML document. Parse error: #{$!.message}" 
      end
    end
    
    def read_and_validate(what)
      @errors = {}
      
      if stack_spec = read_and_check("#{what}.yml")
        if check("script.yml", "the file descriptor has the wrong format") { stack_spec.is_a?(Hash) }
          check("script.yml", "missing field #{"name".try(:foreground, :blue).try(:bright)}")             { stack_spec['name'] }
          if check("script.yml", "missing field #{"type".try(:foreground, :blue).try(:bright)}")          { stack_spec['type'] }    
            check("script.yml", "invalid value for field #{"type".try(:foreground, :blue).try(:bright)}") { stack_spec['type'] == 'script' }
          end
        end
      end

      validate_controls
      validate_requirements
      validate_executions
      validate_validations
      
      stack_spec
    end
    
    def validate_spec(idx, name, item_id, checks)
      file = "config/#{idx}-#{name}.yml"
      
      return unless spec = read_and_check(file)
      return unless check(file, "invalid format") { 
        spec.is_a?(Hash) && spec[name].is_a?(Array) 
      }
      
      spec[name].each_with_index do |item, i|
        checks.each do |check|
          if item_id.nil? or check == item_id
            check(file, "missing #{check} for #{name.singularize} #{i+1}") { item[check] }
          else
            check(file, "missing #{check} for #{name.singularize} #{item[item_id].try(:foreground, :blue).try(:bright)}") { item[check] }
          end
        end
        
        return unless yield(item, i+1) if block_given?
      end
    end
    
    def validate_controls
      validate_spec '01', 'controls', 'name', ['name', 'type'] do |item, i|
        check('config/01-controls.yml', "invalid type '#{item["type"]}' for control #{item["name"].try(:foreground, :blue).try(:bright)}") { 
          %w(Textbox Numericbox Password).include? item['type']
        }
      end
    end
    
    def validate_requirements
      validate_spec '02', 'requirements', nil, ['type', 'data'] do |item, i|
        check("config/02-requirements.yml", "invalid type #{item["type"].try(:foreground, :blue).try(:bright)} for requirement #{i}") { 
          %w(DirExists FileExists ExecutableExists ProcessExists RubyCanLoad RubyGem SymlinkExists).include? item['type']
        }
      end
    end
  
    def validate_executions
      validate_spec '03', 'executions', 'file', ['file', 'description']
    end
    
    def validate_validations
      validate_spec '04', 'validations', nil, ['type', 'data'] do |item, i|
        check('config/04-validations.yml', "invalid type #{item["type"].try(:foreground, :blue).try(:bright)} for validation #{i}") { 
          %w(DirExists FileExists ExecutableExists ProcessExists RubyCanLoad RubyGem SymlinkExists).include? item['type']
        }
      end
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