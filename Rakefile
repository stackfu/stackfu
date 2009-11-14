require 'rubygems'
require 'rake'  
require 'rake/testtask'

Rake::TestTask.new(:test_new) do |test|
  test.libs << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

# remove_task :default
# task :default  => :test

# gem 'hoe', '>= 2.1.0'
# 
# require 'hoe'
# require 'fileutils'

# Hoe.plugin :newgem
# # Hoe.plugin :website
# # Hoe.plugin :cucumberfeatures
# 
# # Generate all the Rake tasks
# # Run 'rake -T' to see list of generated tasks (from gem root directory)
# $hoe = Hoe.spec 'stackfu' do
#   self.developer 'Felipe Coury', 'felipe@stackfu.com'
#   self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
#   self.rubyforge_name       = self.name # TODO this is default value
#   # self.extra_deps         = [['activesupport','>= 2.0.2']]
# 
# end
# # 
# # # require 'newgem/tasks'
# # # Dir['tasks/**/*.rake'].each { |t| load t }
# 
# 
# 
# # TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
task :default => [:test_new]
