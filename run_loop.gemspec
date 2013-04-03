# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "run_loop/version"

Gem::Specification.new do |s|
  s.name        = "run_loop"
  s.version     = RunLoop::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Karl Krukow"]
  s.email       = ["karl@lesspainful.com"]
  s.homepage    = "http://calaba.sh"
  s.summary     = %q{Tools related to running Calabash iOS tests}
  s.description = %q{calabash-cucumber drives tests for native iOS apps. RunLoop provides a number of tools associated with running Calabash tests.}
  s.files         = ["scripts/udidetect"].concat(`git ls-files`.split("\n"))
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = "run-loop"
  s.require_paths = ["lib"]

  s.add_dependency( "thor" )
  s.add_dependency( "json" )
  #s.add_dependency( "open4", "~> 1.3.0")
end
