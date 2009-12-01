require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestRendering < Test::Unit::TestCase
  include StackFu::Rendering
  
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
      
      table = table(:class => Pizza, :collection => pizzas, :display => [:flavor, :size, :price], :ansi => false)
      table.should =~ /^Listing 4 pizzas:/
      table.should =~ /  Flavor       Size   Price/
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
      
      table = table(:class => Pizza, :collection => pizzas, :display => [:flavor, :size, :price], :ansi => false) do |item|
        ["Mah #{item.flavor}", "#{item.size.try(:downcase)}", item.price + 2]
      end
      table.should =~ /^Listing 3 pizzas:/
      table.should =~ /  Flavor           Size   Price/
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
      
      table = table(:class => Dash, :collection => pizzas, :display => [:flavor, :size, :price], :ansi => false) do |item|
        ["Mah #{item.flavor}", "#{item.size.try(:downcase)}", item.price + 2]
      end
      table.should =~ /^Listing 1 dash:/
      table.should =~ /  Flavor          Size   Price/
      table.should =~ /  --------------- ------ -----/
      table.should =~ /  Mah Mozzarella  large  16.99/

      pizzas << Dash.new("Minina", "Large", 14.99)
      
      table = table(:class => Dash, :collection => pizzas, :display => [:flavor, :size, :price], :ansi => false) do |item|
        ["Mah #{item.flavor}", "#{item.size.try(:downcase)}", item.price + 2]
      end
      table.should =~ /^Listing 2 dashes:/
      table.should =~ /  Flavor          Size   Price/
      table.should =~ /  --------------- ------ -----/
      table.should =~ /  Mah Mozzarella  large  16.99/
    end
    
    should "render an empty message if no items" do
      pizzas = []
      table = table(:class => Pizza, :collection => pizzas, :display => [:flavor, :size, :price], :ansi => false)
      table.should =~ /No pizzas./
    end
    
    should "render a custom empty message if no items and custom message passed" do
      pizzas = []
      table = table(:class => Pizza, :collection => pizzas, 
        :display => [:flavor, :size, :price], :empty => "Sorry dude, no pizzas!")
      table.should =~ /Sorry dude, no pizzas!/
    end
    
    should "two objects with same duck type" do
      class Animal
        attr_accessor :name
        def initialize(name)
          @name = name
        end
      end
      
      class Dog < Animal
        def legs; 4; end
      end
      
      class Spider < Animal
        def legs; 8; end
      end
      
      class Fly < Animal
        def legs; 6; end
      end
      
      animals = [Dog.new("Jimmy"), Dog.new("Buddy"), Fly.new("Buggah"), Spider.new("Mommy")]
      table = table(
        :class => [Dog, Fly, Spider], 
        :display => [:name, :legs],
        :collection => animals, :ansi => false
      )

      table.should =~ /^Listing 2 dogs, 1 fly and 1 spider/
      table.should =~ /  Name    Legs /
      table.should =~ /  ------- -----/
      table.should =~ /  Jimmy      4/
      table.should =~ /  Buddy      4/
      table.should =~ /  Buggah     6/
      table.should =~ /  Mommy      8/
    end
    
    should "render a custom headline" do
      pizzas = [Pizza.new("Mozzarella", "Large", 14.99)]
      table = table(
        :class => Pizza, 
        :collection => pizzas, 
        :display => [:flavor, :size, :price],
        :header => "We have some pizzas for you")

      table.should =~ /^We have some pizzas for you/
      table.should_not =~ /^Listing 1 pizza/
    end
  end
end