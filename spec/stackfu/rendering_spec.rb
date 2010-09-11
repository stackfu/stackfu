# Load Spec Helper
require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helper')

describe StackFu::Rendering do
  include StackFu::Rendering
  
  before(:each) do
    class Pizza
      attr_accessor :flavor, :size, :price

      def initialize(flavor, size, price)
        @flavor = flavor
        @size = size
        @price = price
      end
    end
  end
  
  describe '#fill_values_from_options' do
    let(:script) { mock('Script') }

    it "renders textboxes" do
      textbox = mock('Textbox')
      textbox.stubs(:_type).returns('Textbox')
      textbox.stubs(:name).returns('ports')
      textbox.stubs(:label).returns('Ports')
      
      script.stubs(:controls).returns([textbox])

      when_asked "  Ports: ", :answer => "80,23,22"

      render_target({}, script, {})
    end
    
    it "renders numericboxes" do
      numericbox = mock('Numericbox')
      numericbox.stubs(:_type).returns('Numericbox')
      numericbox.stubs(:name).returns('port')
      numericbox.stubs(:label).returns('Port')
      
      script.stubs(:controls).returns([numericbox])

      when_asked "  Port: ", :answer => "80"

      render_target({}, script, {})
    end
    
    it "renders passwords" do
      password = mock('Password')
      password.stubs(:_type).returns('Password')
      password.stubs(:name).returns('password')
      password.stubs(:label).returns('Password')
      
      script.stubs(:controls).returns([password])

      when_asked "  Password: ", :answer => "abcdef"

      render_target({}, script, {})
    end
  end
  
  context "lists" do
    it "renders a list with the object collection and all properties by default" do
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
    
    it "accepts a block and render based on the block" do
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
    
    it "pluralizes the description before the table" do
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
    
    it "renders an empty message if no items" do
      pizzas = []
      table = table(:class => Pizza, :collection => pizzas, :display => [:flavor, :size, :price], :ansi => false)
      table.should =~ /No pizzas./
    end
    
    it "renders a custom empty message if no items and custom message passed" do
      pizzas = []
      table = table(:class => Pizza, :collection => pizzas, 
        :display => [:flavor, :size, :price], :empty => "Sorry dude, no pizzas!")
      table.should =~ /Sorry dude, no pizzas!/
    end

    it "renders two objects with same duck type" do
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
    
    it "renders a custom headline" do
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