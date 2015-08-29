require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)

  RSpec::Core::RakeTask.new(:unit) do |task|
    task.pattern = 'spec/lib/**{,/*/**}/*_spec.rb'
  end
rescue LoadError => _
end

task :ctags do
  sh 'rm -f .git/tags'
  excluded = [
    '--exclude=*.png',
    '--exclude=.screenshots',
    '--exclude=*screenshots*',
    '--exclude=reports',
    '--exclude=*.app',
    '--exclude=*.dSYM',
    '--exclude=*.ipa',
    '--exclude=*.zip',
    '--exclude=*.framework',
    '--exclude=.irb-history',
    '--exclude=.pry-history',
    '--exclude=.idea',
    '--exclude=*.plist',
    '--exclude=.gitignore',
    '--exclude=Gemfile.lock',
    '--exclude=Gemfile',
    '--exclude=docs',
    '--exclude=*.md',
    '--exclude=*.java',
    '--exclude=*.xml',
    '--exclude=.pryrc',
    '--exclude=.irbrc',
    '--exclude=.DS_Store'
  ]
  cmd = "ctags --tag-relative -V -f .git/tags -R #{excluded.join(' ')} --languages=ruby lib/ spec/"
  sh cmd
end

