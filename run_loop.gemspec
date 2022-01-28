# -*- encoding: utf-8 -*-

ruby_files = Dir.glob('{lib}/**/*.rb')
java_scripts = Dir.glob('scripts/**/*.js')
bash_scripts = ["scripts/udidetect",
                "scripts/read-cmd.sh",
                "scripts/timeout3"]
plists = Dir.glob('plists/**/*.plist')

device_agent = ["lib/run_loop/device_agent/bin/iOSDeviceManager",
                "lib/run_loop/device_agent/bin/iOSDeviceManager.LICENSE",
                "lib/run_loop/device_agent/app/DeviceAgent-Runner.app.zip",
                "lib/run_loop/device_agent/ipa/DeviceAgent-Runner.app.zip",
                "lib/run_loop/device_agent/Frameworks.zip"]

vendor_licenses = Dir.glob("./vendor-licenses/*.*")

Gem::Specification.new do |s|
  s.name        = 'run_loop'

  s.version     = begin
    file = "#{File.expand_path(File.join(File.dirname(__FILE__),
                                      "lib", "run_loop", "version.rb"))}"
    m = Module.new
    m.module_eval IO.read(file).force_encoding("utf-8")
    version = m::RunLoop::VERSION
    unless /(\d+\.\d+\.\d+(\.pre\d+)?)/.match(version)
      raise %Q{
Could not parse constant RunLoop::VERSION: '#{version}'
into a valid version, e.g. 1.2.3 or 1.2.3.pre10
}
    end
    version
  end

  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Karl Krukow", "Joshua Moody"]
  s.email       = ["karl.krukow@xamarin.com", "josmoo@microsoft.com"]
  s.homepage    = 'http://calaba.sh'
  s.summary     = %q{The bridge between Calabash iOS and Xcode command-line
tools like instruments and simctl.}
  s.files = ruby_files + java_scripts + bash_scripts + plists + device_agent +
  ["LICENSE", "ThirdPartyNotices.txt"] + vendor_licenses
  s.require_paths = ['lib']
  s.licenses    = ['MIT']
  s.executables = 'run-loop'

  s.required_ruby_version = '>= 2.0'

  s.add_dependency('json')
  s.add_dependency('awesome_print')
  s.add_dependency('thor')
  s.add_dependency('command_runner_ng')
  s.add_dependency("httpclient")
  s.add_dependency("i18n")

  s.add_development_dependency("rspec_junit_formatter")
  s.add_development_dependency("luffa")
  s.add_development_dependency('bundler')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rake')
  s.add_development_dependency("xcpretty")
  s.add_development_dependency("guard-rspec")
  s.add_development_dependency("terminal-notifier")
  s.add_development_dependency("terminal-notifier-guard")
  s.add_development_dependency("guard-bundler")
  # Pin to 3.0.6; >= 3.1.0 requires ruby 2.2. This is guard dependency.
  s.add_development_dependency("listen")
  s.add_development_dependency('stub_env')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-nav')
  s.add_development_dependency('irb')
end
