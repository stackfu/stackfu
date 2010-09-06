module StackFu::Commands
  class DumpCommand < Command
    include StackFu::ApiHooks

    def default(parameters, options)
      script_name = parameters[0]
      
      unless script_name
        puts "You have to tell which script you want to dump."
        return
      end
      
      script = spinner { 
        begin
          Script.find(script_name) 
        rescue ActiveResource::ResourceNotFound 
        end
      }
      
      if script
        if directory?(script_name) 
          unless agree("There is already a folder called '#{script_name}'. Do you want to overwrite its contents?")
            puts "Aborted."
            return false
          end
        end
        
        create_folder(script_name)
        create_file "#{script_name}/script.yml", {
          "type" => "script",
          "name" => script.name,
          "description" => script.respond_to?(:description) ? script.description : ""
        }.to_yaml
        
        create_folder "#{script_name}/config"
        
        if script.respond_to?(:controls)
          controls = map script.controls, "controls" do |c|
            { "name"  => c.name,
              "label" => c.label,
              "type"  => c._type }
          end
        else
          controls = []
        end
        
        if script.respond_to?(:requirements)
          requirements = map script.requirements, "requirements" do |req|
            { "data"   => req.params.attributes["data"],
              "type"   => req._type }
          end
        else
          requirements = []
        end
        
        if script.respond_to?(:executions)
          executions = map script.executions, "executions" do |exec|
            { "description" => exec.description,
              "file"        => exec.description.downcase.gsub(" ", "_") }
          end
        else
          executions = []
        end
        
        
        if script.respond_to?(:validations)
          validations = map script.validations, "validations" do |val|
            { "data"   => val.params.attributes["data"],
              "type"   => val._type }
          end
        else
          validations = []
        end
        
        create_file "#{script_name}/config/01-controls.yml", controls
        create_file "#{script_name}/config/02-requirements.yml", requirements
        create_file "#{script_name}/config/03-executions.yml", executions
        create_file "#{script_name}/config/04-validations.yml", validations
        
        create_folder "#{script_name}/executables"
        script.executions.each do |script|
          create_file "#{script_name}/executables/#{script.description.downcase.gsub(" ", "_")}.sh.erb", script.body
        end
        
        puts "Script #{script_name} dumped successfully..."
      else
        puts "Script '#{script_name}' was not found"
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