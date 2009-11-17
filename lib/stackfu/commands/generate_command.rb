require 'erb'
require 'ostruct'

class GenerateCommand < Command
  alias_subcommand :create => :generate
  subcommand :stack, :required_parameters => [:stack_name]
  error_messages :missing_subcommand => "You have to tell what you want to generate: a stack or a plugin."
  
  Types = { 
    [:checkbox, :combobox, :password, :radio, :textbox] => :control
  }

  def type(t)
    ctrl = t.to_sym
    Types.each_pair do |key, value|
      ctrl = value if key.include?(ctrl)
    end
    ctrl
  end
  
  def stack(parameters, options)
    begin
      stack_name = parameters.shift
      scripts = []
      controls = []
      while (p = parameters.shift)
        name, type = p.split(":")
        
        case type(type)
        when :script
          scripts << [name, template("script.sh.erb", {
            "filename" => name,
            "description" => name.titleize
          })]
          
        when :control
          controls << [name, type]
          
        end
      end
      
      manifest = template("Manifest.yml.erb", {
        "stack_type" => "stack", 
        "name" => stack_name,
        "description" => "Enter a description for this stack here",
        "scripts" => scripts.map { |s| s[0] },
        "controls" => controls
      })
    
      create("#{stack_name}", "Manifest.yml", manifest)
      create("#{stack_name}/scripts")
      scripts.each do |name, script|
        create("#{stack_name}/scripts", "#{name}.sh.erb", scripts.assoc(name).last)
      end
    rescue IOError, Errno::EEXIST
      puts "There was an error creating your stack: #{$!.message}"
    end
  end
  
  private
  
  def template(t, vars)
    file = "#{File.dirname(__FILE__)}/../../../templates/#{t}"
    ERB.new(File.open(file, "r").readlines.join("")).result(OpenStruct.new(vars).send(:binding))
  end
  
  def create(d, f=nil, contents=nil)
    unless File.directory?(d)
      puts "\tcreate  #{d}/"
      FileUtils.mkdir_p(d)
    end

    if f.present?
      f = "#{d}/#{f}"
      puts "\tcreate  #{f}"
      File.open(f, "w") do |file|
        file.write(contents)
      end
    end
  end
end