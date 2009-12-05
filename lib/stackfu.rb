require 'rubygems'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

gem 'activesupport'
gem 'activeresource'
gem 'rainbow', '>=1.0.4'
gem 'highline', '>=1.5.1'
gem 'httparty', '>=0.4.5'

begin
  require 'active_resource'
  require 'active_support'
rescue LoadError
  require 'activeresource'
  require 'activesupport'
end
require 'rainbow'
require 'highline/import'
require 'httparty'

begin
  require 'Win32/Console/ANSI' if RUBY_PLATFORM =~ /mswin/
rescue LoadError
  puts "Hint: if you want to make your output better in windows, install the win32console gem:"
  puts "      gem install win32console"
  puts ""
end

dir = Pathname(__FILE__).dirname.expand_path + 'stackfu'

require "#{dir}/helpers/rendering"
require "#{dir}/helpers/providers_credentials"

require "#{dir}/operating_systems"
require "#{dir}/api_hooks"
require "#{dir}/app"

require "#{dir}/commands/command"
require "#{dir}/commands/help_command"
require "#{dir}/commands/server_command"
require "#{dir}/commands/config_command"
require "#{dir}/commands/generate_command"
require "#{dir}/commands/publish_command"
require "#{dir}/commands/list_command"
require "#{dir}/commands/deploy_command"
require "#{dir}/commands/dump_command"

module StackFu
  VERSION = '0.0.1'
  API = "http://api.stackfu.com"
  CONFIG_FILE = "#{ENV['HOME']}/.stackfu"

  include StackFu::OperatingSystems

  module Exceptions
    class InvalidCommand < StandardError; end
    class InvalidParameter < StandardError; end
  end
  
end

OpenStruct.__send__(:define_method, :id) { @table[:id] || self.object_id }

class Array  
  def to_phrase
    self.to_sentence(:words_connector => ", ", :last_word_connector => " and ")
  end

  def to_structs
    self.map { |hash| OpenStruct.new(hash) }
  end
  
  def to_params 
    self.map { |item| item.to_s.upcase }.join(" ")
  end
end

class String
  def truncate_words(length = 30, end_string = '…')
    words = self.split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end
end

