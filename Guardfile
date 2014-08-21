notification :growl, sticky: false, priority: 0
logger level: :info

guard 'bundler' do
  watch('Gemfile')
end

# must use all_after_pass => false b/c guard will try to run _all_ the specs in
# spec/ regardless of whether or not we are watching that spec file.
# @todo file a bug about all_after_pass
#
# must use all_on_start => false b/c guard will try to run _all_ the specs in the
# spec/ regardless of whether or not we are watching that spec file.
# @todo file a bug about all_on_start
guard :rspec, cmd: 'bundle exec rspec', failed_mode: :focus, all_after_pass: false, all_on_start: false do

  # running the sim specs is no fun because the simulator is always grabbing
  # control of the machine when it launches.
  # @todo Write a regex that will exclude specs beginning with 'run'
  # @todo Partition the specs into directories - those that launch the sim and those that don't
  # @todo File a bug about all_after_pass : true behavior
  # watch(%r{^spec/.+_spec\.rb$})

  Dir.glob('spec/**/*_spec.rb') do |spec|
    if spec == 'spec/run_device_spec.rb'
      watch(spec)
    elsif spec =~ /spec\/run_.+/ or spec == 'spec/sim_control_spec.rb'
      puts "WARN: skipping spec '#{spec}' because it launches the simulator"
    else
      watch(spec)
    end
  end

  watch('spec/spec_helper.rb')
  watch('spec/resources.rb')

  watch(%r{^lib/(.+)\.rb$})
end

