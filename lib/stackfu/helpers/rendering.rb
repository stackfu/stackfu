module StackFu
  module Rendering
    LEFT_MARGIN = 2
    
    def warning(question)
      puts "== WARNING ==".foreground(:red)
      agree(question)
    end
    
    def fill_values_from_options(stack, options)
      params = {}

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
    
      params
    end
  
    def render_target(params, target, options)
      max_length = target.controls.map { |c| c.label.size }.max
    
      target.controls.each do |c|
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
      if (classes = opts[:class]).is_a?(Array)
        single = {}
        plural = {}
        opts[:class].each do |kls|
          single[kls] = kls.name.demodulize.humanize.downcase
          plural[kls] = single[kls].pluralize
        end
      else
        single = opts[:class].name.demodulize.humanize.downcase
        plural = single.pluralize
      end
      labels = opts[:labels]
      main_column = opts[:main_column]
      ascii = opts[:ansi] == false
      header = opts[:header]
    
      if collection.empty?
        msg = opts[:empty]
        msg ||= "No #{plural}."
        return msg
      end
    
      columns = display.inject([]) do |arr, item| 
        label = labels ? labels[item] : item.to_s.titleize
        arr << { :name => item.to_s, :label => label }
      end
    
      display.each_with_index do |column, i|
        max_value_size = collection.map do |item|
          if block_given?
            value = yield(item)[i]
          else
            if item.respond_to?(column)
              value = item.send(column)
            else
              value = ""
            end
          end
          
          value.to_s.size
        end.max
      
        size = [max_value_size, column.to_s.size].max
        columns[i][:size] = size
      end
    
      title = header || if classes.is_a?(Array)
        counter = Hash.new(0)
        collection.each do |item| 
          counter[item.class] += 1
        end
        
        parts = []
        collection.map(&:class).uniq.each do |k|
          v = counter[k]
          parts << "#{v} #{v > 1 ? plural[k] : single[k]}"
        end
        
        "Listing #{parts.to_phrase}:\n"
      else
        "Listing #{collection.size} #{collection.size > 1 ? plural : single}:\n"
      end

      table = []
      if ascii
        table << columns.inject("") { |str, col| str << "#{col[:label].ljust(col[:size])}  " }
        table << columns.inject("") { |str, col| str << "#{"-" * (col[:size]+1)} " }
      else
        # table << columns.inject("") { |str, col| str << "#{col[:label].titleize.ljust(col[:size]+1).underline.foreground(:yellow)} " }
        table << columns.inject("") { |str, col| str << "#{col[:label].ljust(col[:size]+1).underline.foreground(:yellow)}  " }
      end
    
      collection.each do |item|
        values = block_given? ? yield(item) : nil
        
        idx = 0
        table << columns.inject("") do |str, col| 
          if block_given?
            value = values[idx]
            idx += 1
          else
            if item.respond_to?(col[:name])
              value = item.send(col[:name])
            else
              value = ""
            end
          end
        
          just_method = value.is_a?(Numeric) ? :rjust : :ljust

          if ascii
            str << "#{value.to_s.send(just_method, col[:size])}  " 
          else
            if col[:name].to_sym == main_column
              str << "#{value.to_s.send(just_method, col[:size]).foreground(:blue)}   " 
            else
              str << "#{value.to_s.send(just_method, col[:size])}   " 
            end
          end
        end
      end
    
      table.map! { |line| "#{" " * LEFT_MARGIN}#{line}"}
    
      [title, table].flatten.join("\n")
    end

    def spinner(&code)
      chars = %w{ | / - \\ }

      result = nil
      t = Thread.new { 
        result = code.call
      }
      while t.alive?
        print chars[0]
        STDOUT.flush

        sleep 0.1

        print "\b"
        STDOUT.flush

        chars.push chars.shift
      end

      print " \b"
      STDOUT.flush

      t.join
      result
    end
  end
end