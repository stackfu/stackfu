require 'rubygems'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module StackFu
  VERSION = '0.0.1'
  API = "http://api.stackfu.com"
  CONFIG_FILE = "#{ENV['HOME']}/.stackfu"
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
require "#{dir}/commands/help_command"
require "#{dir}/commands/server_command"
require "#{dir}/commands/config_command"

module Exceptions
  class InvalidCommand < StandardError; end
end

class Array
  def to_phrase
    self.to_sentence(:words_connector => ",", :last_word_connector => " and ")
  end
  
  def to_params 
    self.map { |item| item.to_s.upcase }.join(" ")
  end
end