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

FakeWeb.allow_net_connect = false
$testing = true

class Test::Unit::TestCase
  include CustomMatchers
  include IoStub
  include Fixtures

  def command(cmd, settings_present=true)
    App.expects(:settings?).returns(settings_present)
    App.new(*cmd.split(" ")).start
  end

  def setup
    @orig_stdout = $stdout
    $stdout = StringIO.new
    $questions = {}
    $agreements = []
    $disagreements = []
  end
  
  def when_asked(what, options)
    $questions[what] = options[:answer]
  end
  
  def agree_with(what)
    $agreements << what
  end
  
  def disagree_of(what)
    $disagreements << what
  end
  
  def teardown
   $stdout = @orig_stdout
  end
end

module Kernel
  def ask(question, answer_type = String, &details)
    $questions.delete(question) or raise "Unexpected question: #{question}"
  end
  
  def agree(yes_or_no_question, character = nil)
    return true if $agreements.include?(yes_or_no_question)
    return false if $disagreements.include?(yes_or_no_question)
    raise "Unexpected agreement: #{yes_or_no_question}"
  end
end

def d(x); $stderr.puts x; end
