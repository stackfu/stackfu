module Rendering
  LEFT_MARGIN = 2
  
  def render_stack(stack, options)
    params = {}
    max_length = stack.controls.map { |c| c.label.size }.max
    
    stack.controls.each do |c|
      if (opt = options[c.name.to_sym])
        case c._type
        when "Textbox"
          params[c.name] = opt if opt

        when "Numericbox"
          begin
            params[c.name] = Float(opt)
          rescue ArgumentError
            error "Value for #{c.name} should be numeric"
          end

        end
      end
    end
    
    stack.controls.each do |c|
      unless params[c.name]
        case c._type
        when "Textbox"
          params[c.name] = ask("  #{c.label.rjust(max_length)}: ")

        when "Numericbox"
          params[c.name] = ask("  #{c.label.rjust(max_length)}: ", Integer)

        end
      end
    end

    params
  end

  def done(message, more_info=nil)
    puts "#{"Success:".foreground(:green).bright} #{message}"
    puts "\n#{more_info}" if more_info
  end
  
  def error(message, more_info=nil)
    puts "#{"Error:".foreground(:red).bright} #{message}"
    puts "\n#{more_info}" if more_info
  end
  
  def menu_for(name, collection, convert=false)
    choice = choose do |menu|
      menu.header = "Available #{name.pluralize}"
      menu.prompt = "\nSelect the #{name}:"
      menu.shell = true

      collection.each { |p| menu.choice(p.name) }
    end
    
    if convert
      collection.select { |i| i.name == choice }.first.id 
    else
      choice
    end
  end
  
  def table(opts)
    collection = opts[:collection]
    display = opts[:display]
    single = opts[:class].name.demodulize.humanize.downcase
    plural = single.pluralize
    
    if collection.empty?
      msg = opts[:empty]
      msg ||= "No #{plural}."
      return msg
    end
    
    columns = display.inject([]) do |arr, item| 
      arr << { :name => item.to_s, :label => item.to_s }
    end
    
    display.each_with_index do |column, i|
      max_value_size = collection.map do |item|
        value = block_given? ? yield(item)[i] : item.send(column)
        value.to_s.size
      end.max
      
      size = [max_value_size, column.to_s.size].max
      columns[i][:size] = size
    end
    
    title = "Listing #{collection.size} #{collection.size > 1 ? plural : single}:\n"

    table = []
    table << columns.inject("") { |str, col| str << "#{col[:label].ljust(col[:size])}  " }
    table << columns.inject("") { |str, col| str << "#{"-" * (col[:size]+1)} " }
    
    collection.each do |item|
      values = block_given? ? yield(item) : nil
        
      idx = 0
      table << columns.inject("") do |str, col| 
        if block_given?
          value = values[idx]
          idx += 1
        else
          value = item.send(col[:name])
        end
        
        just_method = value.is_a?(Numeric) ? :rjust : :ljust

        str << "#{value.to_s.send(just_method, col[:size])}  " 
      end
    end
    
    table.map! { |line| "#{" " * LEFT_MARGIN}#{line}"}
    
    [title, table].flatten.join("\n")
  end
end