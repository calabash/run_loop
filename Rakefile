require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb').delete_if { |path| path =~ /run_device_spec.rb/ }
end
