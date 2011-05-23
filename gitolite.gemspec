# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gitolite/version"

Gem::Specification.new do |s|
  s.name        = "gitolite"
  s.version     = Gitolite::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stafford Brunk"]
  s.email       = ["wingrunr21@gmail.com"]
  s.homepage    = "https://www.github.com/wingrunr21/gitolite"
  s.summary     = %q{A Ruby gem for manipulating the gitolite git backend via the gitolite-admin repository.}
  s.description = %q{This gem is designed to provide a Ruby interface to the gitolite git backend system.  This gem aims to provide all management functionality that is available via the gitolite-admin repository (like SSH keys, repository permissions, etc)}

  s.rubyforge_project = "gitolite"

  s.add_development_dependency "rspec", "~> 2.6.0"
  s.add_development_dependency "forgery", "~> 0.3.8"
  s.add_dependency "grit", "~> 2.4.1"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
