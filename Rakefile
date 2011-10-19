require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task :test => :spec
task :default => :spec

# FIXME warns "already initialized constant Task"
# FIXME aborts with "uninitialized constant RDoc::VISIBILITIES"
# require 'rdoc/task'
#
# RDoc::Task.new do |rdoc|
#   rdoc.main = "README.rdoc"
#   rdoc.rdoc_files.include("README.rdoc", "lib/**/*.rb")
# end
