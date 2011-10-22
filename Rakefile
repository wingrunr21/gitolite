require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

# Rake tasks from https://github.com/mojombo/rakegem/blob/master/Rakefile

# Helper Functions
def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end

def version
  line = File.read("lib/#{name}/version.rb")[/^\s*VERSION\s*=\s*.*/]
  line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
end

# Standard tasks
require 'rcov'
RSpec::Core::RakeTask.new(:spec)
task :test => :spec
task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "#{name} #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/#{name}.rb"
end
