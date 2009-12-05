module StackFu
  class DumpCommand < Command
    include ApiHooks

    error_messages :missing_subcommand => "You have to tell what you want to dump: a stack or a plugin"
    subcommand :stack, :required_parameters => [:stack_name]
    
    def stack(parameters, options)
      stack_name = parameters[0]
      stack = spinner { Stack.find(:all, :params => { :stack => { :name => stack_name } }).first }
      
      if stack
        if directory?(stack_name) 
          unless agree("There is already a folder called '#{stack_name}'. Do you want to overwrite its contents?")
            puts "Aborted."
            return false
          end
        end
        
        create_folder(stack_name)
        create_file "#{stack_name}/stack.yml", {
          "type" => "stack",
          "name" => stack.name,
          "description" => stack.description,
          "operating_system" => stack.operating_system.to_s
        }.to_yaml
        
        create_folder "#{stack_name}/config"
        
        controls = map stack.controls, "controls" do |c|
          { "name"  => c.name,
            "label" => c.label,
            "type"  => c._type }
        end
        
        requirements = map stack.requirements, "requirements" do |req|
          { "data"  => req.data,
            "error" => req.error,
            "type"  => req._type }
        end
        
        executions = map stack.executions, "scripts" do |exec|
          { "description" => exec.description,
            "file"        => exec.description.downcase.gsub(" ", "_") }
        end
        
        validations = map stack.validations, "validations" do |val|
          { "data"  => val.data,
            "error" => val.error,
            "type"  => val._type }
        end
        
        create_file "#{stack_name}/config/01-controls.yml", controls
        create_file "#{stack_name}/config/02-requirements.yml", requirements
        create_file "#{stack_name}/config/03-scripts.yml", executions
        create_file "#{stack_name}/config/04-validations.yml", validations
        
        create_folder "#{stack_name}/script"
        stack.executions.each do |script|
          create_file "#{stack_name}/script/#{script.description.downcase.gsub(" ", "_")}.sh.erb", script.data
        end
        
        puts "Stack #{stack_name} dumped successfully..."
      else
        puts "Stack '#{stack_name}' was not found"
      end
    end
    
    private
    
    def directory?(folder)
      File.directory?(folder)
    end
    
    def map(collection, name)
      { name => collection.map { |item| yield item } }.to_yaml
    end
    
    def create_folder(folder)
      puts "\tcreate  #{folder}/"
      mkdir folder
    end
    
    def mkdir(folder)
      unless File.directory?(folder)
        Dir.mkdir folder
      end
    end
    
    def create_file(file, contents)
      puts "\tcreate  #{file}"
      write_file(file, contents)
    end
    
    def write_file(file, contents)
      File.open(file, "w") do |file|
        file.write(contents)
      end      
    end
  end
end