# -*- encoding: utf-8 -*-

ruby_files = Dir.glob('{lib}/**/*.rb')
java_scripts = Dir.glob('scripts/*.js')
bash_scripts = ['scripts/udidetect', 'scripts/read-cmd.sh', 'scripts/timeout3']
plists = Dir.glob('plists/**/*.plist')

Gem::Specification.new do |s|
  s.name        = 'run_loop'
  s.version     =
        lambda {
          file = File.join('./', 'lib', 'run_loop', 'version.rb')
          lines = File.readlines(file)
          version_regex = /\s*VERSION\s*=\s*/
          version_lines = lines.select { |line| line =~ version_regex }

          if version_lines.nil? || version_lines.empty?
            raise "Could not find a VERSION line in '#{file}'"
          end

          if version_lines.count != 1
            raise "Found multiple matches for VERSION\n#{version_lines}"
          end

          match_regex = /VERSION\s*=\s*'(\d\.\d\.\d(\.pre\d+)?)'/
          version_line = version_lines.first.strip
          match = version_line[match_regex,0]
          unless match == version_line
            raise "Could not parse #{version_line} into a valid version, e.g. 1.2.3 or 1.2.3.pre10"
          end

          version_line[match_regex,1]
        }.call
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Karl Krukow']
  s.email       = ['karl.krukow@xamarin.com']
  s.homepage    = 'http://calaba.sh'
  s.summary     = %q{The bridge between Calabash iOS and Xcode command-line
tools like instruments and simctl.}
  s.files         = ruby_files + java_scripts + bash_scripts + plists + ['LICENSE']
  s.require_paths = ['lib']
  s.licenses    = ['MIT']
  s.executables = 'run-loop'

  s.required_ruby_version = '>= 1.9'

  s.add_dependency('json', '~> 1.8')
  s.add_dependency 'retriable', '>= 1.3.3.1', '< 2.1'
  s.add_dependency('awesome_print', '~> 1.2')
  s.add_dependency('CFPropertyList','~> 2.2')
  s.add_dependency('thor', '>= 0.18.1', '< 1.0')

  if RUBY_VERSION >= '2.0'
    s.add_dependency('command_runner_ng', '>= 0.0.2')
  end

  s.add_development_dependency('luffa', '>= 1.1.0', '< 2.0')
  s.add_development_dependency('bundler', '~> 1.6')
  s.add_development_dependency('travis', '~> 1.8')
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('rake', '~> 10.3')
  s.add_development_dependency('guard-rspec', '~> 4.3')
  s.add_development_dependency('guard-bundler', '~> 2.0')
  s.add_development_dependency('growl', '~> 1.0')
  s.add_development_dependency('stub_env', '>= 1.0.1', '< 2.0')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-nav')
end
