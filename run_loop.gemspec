# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "run_loop/version"

Gem::Specification.new do |s|
  s.name        = "run_loop"
  s.version     = RunLoop::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Karl Krukow"]
  s.email       = ['karl.krukow@xamarin.com']
  s.homepage    = "http://calaba.sh"
  s.summary     = %q{Tools related to running Calabash iOS tests}
  s.description = %q{calabash-cucumber drives tests for native iOS apps. RunLoop provides a number of tools associated with running Calabash tests.}
  s.files         = Dir.glob('{bin,lib}/**/*') + Dir.glob('scripts/*.js') + ['scripts/udidetect', 'scripts/calabash.lldb.erb', 'scripts/read-cmd.sh', 'LICENSE']
  s.executables   = "run-loop"
  s.require_paths = ["lib"]
  s.licenses    = ['MIT']

  s.required_ruby_version = '>= 1.9'

  s.add_dependency('thor', '>= 0.18')
  s.add_dependency('json', '~> 1.8')
  # matches XTC requirement; would like to use ~> 1.4.0
  s.add_dependency 'retriable', '~> 1.3.3.1'
  s.add_dependency('awesome_print', '~> 1.2.0')
  s.add_dependency('CFPropertyList','~> 2.2')

  s.add_development_dependency('bundler', '~> 1.6')
  s.add_development_dependency('travis', '~> 1.7')
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('rake', '~> 10.3')
  s.add_development_dependency('guard-rspec', '~> 4.3')
  s.add_development_dependency('guard-bundler', '~> 2.0')
  s.add_development_dependency('growl', '~> 1.0')
  s.add_development_dependency('rb-readline', '~> 0.5')
end
