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

require 'support/fixture_generators'
require 'support/web_fixtures'
require 'support/custom_matchers'

FakeWeb.allow_net_connect = false
$testing = true

MongoMapper.database = 'stackfu-test'
MongoMapper.database.collections.each do |c|
  c.remove
end

class Test::Unit::TestCase
  include CustomMatchers
  include WebFixtures
  include FixtureGenerators
end

