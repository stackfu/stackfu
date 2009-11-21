require 'erb'
require 'ostruct'

class GenerateCommand < Command
  aliases :create
  subcommand :stack, :required_parameters => [:stack_name]
  error_messages :missing_subcommand => "You have to tell what you want to generate: a stack or a plugin."
  
  Types = { 
    [:checkbox, :numericbox, :combobox, :password, :radio, :textbox] => :control
  }

  def type(t)
    return :unknown unless t
    
    ctrl = t.to_sym
    Types.each_pair do |key, value|
      ctrl = value if key.include?(ctrl)
    end
    ctrl
  end
  
  def stack(parameters, options)
    begin
      stack_name = parameters.shift
      items = {}
      while (p = parameters.shift)
        name, type = p.split(":")
        
        case type(type)
        when :script
          (items["scripts"]||=[]) << [name, template("script.sh.erb", {
            "filename" => name,
            "description" => name.titleize
          })]
          
        when :control
          (items["controls"]||=[]) << [name, type]
          
        else
          raise Exceptions::InvalidParameter, 
            "Don't know how to generate a stack with #{type ? "#{type} " : ""}#{name}. Use 'stackfu help generate' for more information."
          
        end
      end
      
      stack = template("stack.yml.erb", {
        "stack_type" => "stack", 
        "name" => stack_name,
        "description" => "Enter a description for this stack here"
      })
      
      create("#{stack_name}", "stack.yml", stack)

      i = 1
      %w[controls requirements scripts validations].each do |item|
        template_name = "0#{i}-#{item}.yml"
        create "#{stack_name}/config", template_name, template("#{template_name}.erb", {
          item => items[item]
        })
        i += 1
      end
    
      items["scripts"].try(:each) do |item|
        create("#{stack_name}/script", "#{item.first}.sh.erb", item.last)
      end or create("#{stack_name}/script")
      
      puts "Stack #{stack_name} created successfully"
    rescue Exceptions::InvalidParameter
      puts $!.message
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