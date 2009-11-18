require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestRendering < Test::Unit::TestCase
  include Rendering
  
  class Pizza
    attr_accessor :flavor, :size, :price
    
    def initialize(flavor, size, price)
      @flavor = flavor
      @size = size
      @price = price
    end
  end

  context "lists" do
    should "render a list with the object collection and all properties by default" do
      pizzas = [
        Pizza.new("Mozzarella", "Large", 14.99),
        Pizza.new("Margheritta", "Large", 15.99),
        Pizza.new("Pequenita", nil, 5.99),
        Pizza.new("Pepperoni", "Large", 17.99)
      ]
      
      table = table(:class => Pizza, :collection => pizzas, :display => [:flavor, :size, :price])
      table.should =~ /^Listing 4 pizzas:/
      table.should =~ /  flavor       size   price/
      table.should =~ /  ------------ ------ -----/
      table.should =~ /  Mozzarella   Large  14.99/
      table.should =~ /  Margheritta  Large  15.99/
      table.should =~ /  Pequenita            5.99/
      table.should =~ /  Pepperoni    Large  17.99/
    end
    
    should "accept a block and render based on the block" do
      pizzas = [
        Pizza.new("Mozzarella", "Large", 14.99),
        Pizza.new("Margheritta", "Large", 15.99),
        Pizza.new("Pequenita", nil, 5.99),
      ]
      
      table = table(:class => Pizza, :collection => pizzas, :display => [:flavor, :size, :price]) do |item|
        ["Mah #{item.flavor}", "#{item.size.try(:downcase)}", item.price + 2]
      end
      table.should =~ /^Listing 3 pizzas:/
      table.should =~ /  flavor           size   price/
      table.should =~ /  ---------------- ------ -----/
      table.should =~ /  Mah Mozzarella   large  16.99/
      table.should =~ /  Mah Margheritta  large  17.99/
      table.should =~ /  Mah Pequenita            7.99/
    end
    
    should "pluralize the description before the table" do
      class Dash < Pizza
      end
      
      pizzas = [
        Dash.new("Mozzarella", "Large", 14.99)
      ]
      
      table = table(:class => Dash, :collection => pizzas, :display => [:flavor, :size, :price]) do |item|
        ["Mah #{item.flavor}", "#{item.size.try(:downcase)}", item.price + 2]
      end
      table.should =~ /^Listing 1 dash:/
      table.should =~ /  flavor          size   price/
      table.should =~ /  --------------- ------ -----/
      table.should =~ /  Mah Mozzarella  large  16.99/

      pizzas << Dash.new("Minina", "Large", 14.99)
      
      table = table(:class => Dash, :collection => pizzas, :display => [:flavor, :size, :price]) do |item|
        ["Mah #{item.flavor}", "#{item.size.try(:downcase)}", item.price + 2]
      end
      table.should =~ /^Listing 2 dashes:/
      table.should =~ /  flavor          size   price/
      table.should =~ /  --------------- ------ -----/
      table.should =~ /  Mah Mozzarella  large  16.99/
    end
    
    should "render an empty message if no items" do
      pizzas = []
      table = table(:class => Pizza, :collection => pizzas, :display => [:flavor, :size, :price])
      table.should =~ /No pizzas./
    end
    
    should "render a custom empty message if no items and custom message passed" do
      pizzas = []
      table = table(:class => Pizza, :collection => pizzas, 
        :display => [:flavor, :size, :price], :empty => "Sorry dude, no pizzas!")
      table.should =~ /Sorry dude, no pizzas!/
    end
  end
end