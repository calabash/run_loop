# Guard requires terminal-notifier-guard
# https://github.com/Codaisseur/terminal-notifier-guard
# TL;DR:
# $ brew install terminal-notifier-guard
notification :terminal_notifier, sticky: false, priority: 0 if `uname` =~ /Darwin/

logger level: :info
clearing :on

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

# NOTE: This Guardfile only watches unit specs.
# Automatically running the integration specs would repeatedly launch the
# simulator, stealing screen focus and making everyone cranky.

options =
      {
            cmd: 'bundle exec rspec',
            spec_paths: ['spec/lib'],
            failed_mode: :focus,
            all_after_pass: true,
            all_on_start: true
      }

guard(:rspec, options) do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/run_loop/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('lib/run_loop.rb')  { 'spec/lib' }
  watch('spec/spec_helper.rb')  { 'spec/lib' }
  watch('spec/resources.rb')  { 'spec/lib' }
  watch('spec/resources/instruments_output') { 'spec/lib' }
end
