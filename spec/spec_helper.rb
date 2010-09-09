# Require RSpec
require 'rubygems'
require 'rspec'
require 'webmock/rspec'
require 'pp'

# Load Webbynode Class
require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'stackfu')

# Set Testing Environment
$testing = true
WebMock.disable_net_connect!
HighLine.track_eof = false

# Reads out a file from the fixtures directory

module StackFuHelpers
  def read_fixture(file)
    File.read(File.join(File.dirname(__FILE__), "fixtures", file))
  end
  
  def prepare_raise(method, uri, error)
    request = stub_request(method, 
      "#{StackFu::API.gsub("http://", "http://abc123:X@")}#{uri}")
    request.to_raise(error)
  end
  
  def prepare_multi(method, uri, *fixtures)
    d "#{StackFu::API.gsub("http://", "http://abc123:X@")}#{uri}"
    d fixtures.map { |f| read_fixture(f) }

    request = stub_request(method, 
      "#{StackFu::API.gsub("http://", "http://abc123:X@")}#{uri}")
      
    request.to_return(fixtures.map { |f| read_fixture(f) })
  end
  
  def prepare(method, uri, fixture=uri, options=nil)
    request = stub_request(method, 
      "#{StackFu::API.gsub("http://", "http://abc123:X@")}#{uri}")

    request = request.with(options) if options

    request.to_return(read_fixture(fixture))
  end
  
  def when_asked_to_choose(what, options)
    $actions << { :type => "choose", :action => options.merge(:prompt => what) }
  end
  
  def when_asked(what, options)
    $actions << { :type => "ask", :action => [what, options[:answer]] }
  end
  
  def agree_with(what)
    $actions << { :type => "agree", :action => what }
  end
  
  def disagree_of(what)
    $actions << { :type => "disagree", :action => what }
  end
  
  def redirect_stdout
    @orig_stdout = $stdout
    $stdout = StringIO.new
  end
  
  def command(cmd, settings_present=true)
    redirect_stdout
    cmd ||= ""
    StackFu::App.expects(:settings?).returns(settings_present)
    if settings_present
      StackFu::App.any_instance.expects(:load_config).returns({ :login => "flipper", :token => "abc123" })
    end
    StackFu::App.new(cmd.split(" ")).start
  end

  def stdout
    if @orig_stdout
      $stdout.rewind
      @result = $stdout.read
      $stdout = @orig_stdout
      @orig_stdout = nil
    end
    
    @result
  end

  def debug(s)
    @orig_stdout.puts s
  end
end

Rspec.configure do |config|
  config.mock_with :mocha
  
  config.include WebMock
  config.include StackFuHelpers
  config.include Rspec::Matchers
  
  config.before(:each) do
    $actions = []
    $asked = []
  end
  
  config.after(:each) do
    stdout if @orig_stdout
    asked = $asked.map { |s| "  - #{s}" }.join("\n")
    unless $actions.empty?
      questions = $actions.map do |q| 
        info = case q[:type]
        when "ask"
          q[:action].first

        when "choose"
          txt = "'#{q[:action][:prompt]}'"
          txt << " with options '#{q[:action][:with_options].join(", ")}'" if q[:action][:with_options]
        else
          q[:action]
        end

        "  - #{q[:type]} #{info}" 
      end.join("\n")
      fail "Expected questions not asked:\n#{questions}\nQuestions responded:\n#{asked}\n"
    end
  end
end

module Kernel
  def choose(*items, &details)
    if (action = $actions.first)
      if action[:type] == "choose"
        item = OpenStruct.new
        class << item
          def choice(*args)
            (self.choices||=[]) << args
          end
        end
        
        details.call item
        
        exp_action = $actions.shift[:action]
        item.prompt.should == exp_action[:prompt]
        
        exp_action[:with_options].try(:each) do |opt|
          item.choices.flatten.include?(opt).should == true
        end
        
        if (answer = exp_action[:answer]).is_a?(Numeric)
          item.choices[answer][0]
        else
          answer
        end
      end
    else
      fail "Unexpected choose"
    end
  end
  
  def ask(question, answer_type = String, &details)
    if (action = $actions.first)
      matches = if (expected = action[:action].first).is_a?(Regexp)
        question =~ expected
      else
        question == expected
      end

      if action[:type] == "ask" and matches
        $asked << "responded to ask #{action[:action].first} with #{action[:action].last}"
        exp_action = $actions.shift
        result = exp_action[:action].last
        return result
      end
    
      fail "Expected to #{action[:type]} #{action[:action].inspect} but asked #{question.inspect}"
    else
      fail "Unexpected ask #{question.inspect}"
    end
  end
  
  def agree(yes_or_no_question, character = nil)
    action = $actions.first
    if action and action[:action] == yes_or_no_question
      if action[:type] == "agree" or action[:type] == "disagree"
        $asked << "#{action[:type]}d to #{action[:action]}"
        result = $actions.shift[:type] == "agree"
        # d "#{action[:type]} #{yes_or_no_question} => #{result}"
        return result
      end
    end
    
    if action
      fail "Expected to #{action[:type]} #{action[:action].inspect} but asked to agree with #{yes_or_no_question.inspect}"
    else
      fail "Unexpected agreement #{yes_or_no_question.inspect}"
    end
  end
end

def d(x); $stderr.puts x.pretty_inspect; end
def rd(x); $stderr.puts x; end