#!/usr/bin/env ruby

require 'tmpdir'
require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))


spec_resources_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec', 'resources'))

Dir.chdir spec_resources_dir do
  do_system('rm -rf chou-cal.app')
  do_system('rm -rf chou-cal.ipa')
  do_system('rm -rf chou.app')
  do_system('rm -rf chou.ipa')

  unless travis_ci?
    do_system('rm -rf dylibs')
  end
end

working_directory = Dir.mktmpdir

Dir.chdir working_directory do

  do_system('git clone --depth 1 --recursive https://github.com/calabash/calabash-ios-server')
  server_dir = File.expand_path(File.join(working_directory, 'calabash-ios-server'))

  Dir.chdir server_dir do
    install_gem 'xcpretty'
    do_system('make framework')
    do_system('zip -y -q -r calabash.framework.zip calabash.framework')

    unless travis_ci?
      do_system('make dylibs')
      do_system("mv calabash-dylibs #{spec_resources_dir}/dylibs")
    end
  end

  framework_zip = File.expand_path(File.join(server_dir, 'calabash.framework.zip'))

  do_system('git clone --depth 1 --recursive https://github.com/jmoody/animated-happiness')
  Dir.chdir './animated-happiness/chou' do
    do_system('rm -rf calabash.framework')
    do_system("cp #{framework_zip} ./")
    do_system('unzip calabash.framework.zip')
    do_system('make all')
    do_system("mv chou-cal.app #{spec_resources_dir}/")
    do_system("mv chou-cal.ipa #{spec_resources_dir}/")
    do_system("mv chou.app #{spec_resources_dir}/")
    do_system("mv chou.ipa #{spec_resources_dir}/")
  end

end
