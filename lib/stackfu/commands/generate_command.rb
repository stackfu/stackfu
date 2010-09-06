require 'erb'
require 'ostruct'

module StackFu::Commands
  class GenerateCommand < Command
    aliases :create
  
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
    
    def plugin(parameters, options)
      generate("plugin", parameters, options)
    end
    
    def stack(parameters, options)
      generate("stack", parameters, options)
    end
  
    def default(parameters, options)
      what = 'script'
      begin
        item_name = parameters.shift
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
              "Don't know how to generate a #{what} with #{type ? "#{type} " : ""}#{name}. Use 'stackfu help generate' for more information."
          
          end
        end
      
        stack = template("stack.yml.erb", {
          "name" => item_name,
          "description" => "Enter a description for this script here"
        })
      
        create("#{item_name}", "#{what}.yml", stack)

        i = 1
        %w[controls requirements executions validations].each do |item|
          template_name = "0#{i}-#{item}.yml"
          create "#{item_name}/config", template_name, template("#{template_name}.erb", {
            item => items[item]
          })
          i += 1
        end
    
        items["scripts"].try(:each) do |item|
          create("#{item_name}/executables", "#{item.first}.sh.erb", item.last)
        end or create("#{item_name}/executables")
      
        puts "#{what.titleize} #{item_name} created successfully"
      rescue Exceptions::InvalidParameter
        puts $!.message
      rescue IOError, Errno::EEXIST
        puts "There was an error creating your #{what}: #{$!.message}"      
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
        ::FileUtils.mkdir_p(d)
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
end