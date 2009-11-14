require 'rubygems'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module StackFu
  VERSION = '0.0.1'
end

gem 'activesupport'
gem 'rainbow', '>=1.0.4'
gem 'highline', '>=1.5.1'
gem 'httparty', '>=0.4.5'

require 'activesupport'
require 'rainbow'
require 'stackfu'
require 'highline/import'
require 'httparty'

dir = Pathname(__FILE__).dirname.expand_path + 'stackfu'

require "#{dir}/app"

require "#{dir}/commands/command"
require "#{dir}/commands/help"
require "#{dir}/commands/server"
