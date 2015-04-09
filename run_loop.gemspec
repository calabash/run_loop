# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "run_loop/version"

ruby_files = Dir.glob('{lib}/**/*')
java_scripts = Dir.glob('scripts/*.js')
bash_scripts = ['scripts/udidetect', 'scripts/read-cmd.sh', 'scripts/timeout3']

Gem::Specification.new do |s|
  s.name        = "run_loop"
  s.version     = RunLoop::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Karl Krukow"]
  s.email       = ['karl.krukow@xamarin.com']
  s.homepage    = "http://calaba.sh"
  s.summary     = %q{The bridge between Calabash iOS and Xcode command-line
tools like instruments and simctl.}
  s.files         = ruby_files + java_scripts + bash_scripts + ['LICENSE']
  s.require_paths = ["lib"]
  s.licenses    = ['MIT']
  s.executables = 'run-loop'

  s.required_ruby_version = '>= 1.9'

  s.add_dependency('json', '~> 1.8')
  s.add_dependency 'retriable', '>= 1.3.3.1', '< 2.1'
  s.add_dependency('awesome_print', '~> 1.2')
  s.add_dependency('CFPropertyList','~> 2.2')
  s.add_dependency('thor', '>= 0.18.1', '< 1.0')

  s.add_development_dependency('luffa', '~> 1.0', '>= 1.0.4')
  s.add_development_dependency('bundler', '~> 1.6')
  s.add_development_dependency('travis', '~> 1.7')
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('rake', '~> 10.3')
  s.add_development_dependency('guard-rspec', '~> 4.3')
  s.add_development_dependency('guard-bundler', '~> 2.0')
  s.add_development_dependency('growl', '~> 1.0')
  s.add_development_dependency('rb-readline', '~> 0.5')
  s.add_development_dependency('stub_env', '>= 1.0.1', '< 2.0')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-nav')
end
