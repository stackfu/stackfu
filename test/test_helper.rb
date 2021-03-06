require File.expand_path(File.dirname(__FILE__) + '/../lib/stackfu')

gem 'fcoury-matchy', '0.4.0'
gem 'shoulda', '2.10.2'
gem 'timecop', '0.3.1'
gem 'mocha', '>=0.9.4'
gem 'fakeweb', '>=1.2.7'
gem 'phocus', '>=1.1'
gem 'uuid', '>=2.0.2'

require 'matchy'
require 'shoulda'
require 'fakeweb'
require 'phocus'
require 'mocha'
require 'uuid'
require 'pp'

require 'support/custom_matchers'
require 'support/io_stub'
require 'support/fixtures'

HighLine.track_eof = false
FakeWeb.allow_net_connect = false
$testing = true

class Test::Unit::TestCase
  include CustomMatchers
  include IoStub
  include Fixtures
  include StackFu

  def command(cmd, settings_present=true)
    cmd ||= ""
    App.expects(:settings?).returns(settings_present)
    if settings_present
      App.any_instance.expects(:load_config).returns({ :login => "flipper", :token => "abc123" })
    end
    App.new(cmd.split(" ")).start
  end

  def setup
    FakeWeb.clean_registry
    @orig_stdout = $stdout
    $stdout = StringIO.new
    $actions = []
    $asked = []
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
  
  def teardown
    $stdout = @orig_stdout
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

module StackFu
  class ConfigCommand
    def save_config(login, token)
    end
  end
end

class Array
  def delete_first(value=nil)
    result = nil
    self.each_index do |i|
      if block_given? and yield(self[i])
        result = self.delete_at(i)
        break
      end 
      if value and self[i] == value
        result = self.delete_at(i) 
        break 
      end
    end
    
    return result unless result and result.empty?
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

def d(x); $stderr.puts x; end
def ppd(x); $stderr.puts x.pretty_inspect; end
