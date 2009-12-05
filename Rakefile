require 'rubygems'
require 'rake'  
require 'rake/testtask'

require 'echoe'  
  
Echoe.new('stackfu', '0.1.0') do |p|  
  p.description     = "StackFu Backend"  
  p.url             = "http://stackfu.com/cli"  
  p.author          = "Felipe Coury"
  p.email           = "felipe@stackfu.com"  
  p.ignore_pattern  = ["tmp/*", "script/*"]  
  p.dependencies = [
    ['activeresource','>= 2.3.4'],
    ['activesupport','>= 2.3.4'],
    ['rainbow', '>=1.0.4'],
    ['highline', '>=1.5.1'],
    ['httparty', '>=0.4.5']
  ]
  p.install_message = <<EOS

  --==-- StackFu - Server Deployment Engine --==--

  To get started:
  	stackfu

  To get more help:
  	stackfu help

  And now: Deploy it, grasshopper!

EOS
end

Rake::TestTask.new(:test_new) do |test|
  test.libs << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
desc 'Measures test coverage using rcov'
namespace :rcov do
  desc 'Output unit test coverage of plugin.'
  Rcov::RcovTask.new(:unit) do |rcov|
    rcov.libs << 'test'
    rcov.ruby_opts << '-rubygems'
    rcov.pattern    = 'test/unit/**/test_*.rb'
    rcov.output_dir = 'rcov'
    rcov.verbose    = true
    rcov.rcov_opts << '--exclude "gems/*"'
  end
end

desc 'update changelog'  
task :changelog do  
  File.open('CHANGELOG', 'w+') do |changelog|  
    `git log -z --abbrev-commit`.split("\0").each do |commit|  
      next if commit =~ /^Merge: \d*/  
      ref, author, time, _, title, _, message = commit.split("\n", 7)  
      ref = ref[/commit ([0-9a-f]+)/, 1]  
      author = author[/Author: (.*)/, 1].strip  
      time = Time.parse(time[/Date: (.*)/, 1]).utc  
      title.strip!  
  
      changelog.puts "[#{ref} | #{time}] #{author}"  
      changelog.puts '', " * #{title}"  
      changelog.puts '', message.rstrip if message  
      changelog.puts  
    end  
  end  
end