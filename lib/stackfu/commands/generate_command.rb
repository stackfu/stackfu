require 'erb'
require 'ostruct'

class GenerateCommand < Command
  alias_subcommand :create => :generate
  subcommand :stack, :required_parameters => [:stack_name]
  error_messages :missing_subcommand => "You have to tell what you want to generate: a stack or a plugin."
  
  def stack(parameters, options)
    begin
      stack_name = parameters.shift
      scripts = []
      while (p = parameters.shift)
        name, type = p.split(":")
        scripts << [name, template("script.sh.erb", {
          "filename" => name,
          "description" => name.titleize
        })]
      end

      manifest = template("Manifest.yml.erb", {
        "stack_type" => "stack", 
        "name" => parameters[0],
        "description" => "Enter a description for this stack here",
        "scripts" => scripts.map { |s| s[0] }
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