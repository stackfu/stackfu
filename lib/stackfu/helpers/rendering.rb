module Rendering
  LEFT_MARGIN = 2
  
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