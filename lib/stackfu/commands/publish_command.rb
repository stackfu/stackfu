class PublishCommand < Command
  include ApiHooks

  def default(parameters, options)
    initialize_api($config)
    begin
      stack_spec = YAML.load(read("stack.yml"))
      %w[controls requirements scripts validations].each_with_index do |item, i|
        if (from_yaml = YAML.load(read("config/0#{i+1}-#{item}.yml")))
          stack_spec[item] = from_yaml[item]
        end
      end
      
      stack = Stack.new(stack_spec)
      stack.save
    rescue ActiveResource::ServerError
      puts "There was an error publishing your stack: #{$!.message}"
    rescue Errno::ENOENT
      puts "Couldn't find a stack on current folder. Make sure you have a file named 'stack.yml'."
    end
  end
  
  private
  
  def read(file)
    File.open(file, "r").readlines.join("")
  end
  
  def load_stack
  end
end