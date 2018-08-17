require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |task|
    task.pattern = 'spec/lib/**{,/*/**}/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:unit) do |task|
    task.pattern = 'spec/lib/**{,/*/**}/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:integration) do |task|
    task.pattern = 'spec/integration/**{,/*/**}/*_spec.rb'
  end

rescue LoadError => _
end

namespace :device_agent do

  desc "Install DeviceAgent binaries"
  task :install => [:clean, :build, :expand]

  def colorize(string, color)
    "\033[#{color}m#{string}\033[0m"
  end

  def cyan(string)
    colorize(string, 36)
  end

  def green(string)
    colorize(string, 32)
  end

  def magenta(string)
    colorize(string, 35)
  end

  def log_unix_cmd(msg)
    puts cyan("EXEC: #{msg}") if msg
  end

  def log_info(msg)
    puts green("INFO: #{msg}") if msg
  end

  def banner(msg)
    puts ""
    puts magenta("######## #{msg} ########")
    puts ""
  end

  def device_agent_dir
    @device_agent_dir ||= begin
      dir = File.join(".", "lib", "run_loop", "device_agent")
      File.expand_path(dir)
    end
  end

  def frameworks_dir
    @frameworks_dir ||= File.join(device_agent_dir, "Frameworks")
  end

  def frameworks_zip
    @frameworks_zip ||= "#{frameworks_dir}.zip"
  end

  def app_dir
    @app_dir ||= File.join(device_agent_dir, "app", "DeviceAgent-Runner.app")
  end

  def app_zip
    @app_zip ||= "#{app_dir}.zip"
  end

  def ipa_dir
    @ipa_dir ||= File.join(device_agent_dir, "ipa", "DeviceAgent-Runner.app")
  end

  def ipa_zip
    @ipa_zip ||= "#{ipa_dir}.zip"
  end

  def bin
    @bin ||= File.join(device_agent_dir, "bin", "iOSDeviceManager")
  end

  def cli_json
    @cli_json ||= File.join(device_agent_dir, "bin", "CLI.json")
  end

  def cbx_paths
    @cbx_paths ||= begin
      [
        File.expand_path(File.join(app_dir, "..", "CBX-Runner.app")),
        File.expand_path(File.join(app_dir, "..", "CBX-Runner.app.zip")),
        File.expand_path(File.join(ipa_dir, "..", "CBX-Runner.app")),
        File.expand_path(File.join(ipa_dir, "..", "CBX-Runner.app.zip")),
      ]
    end
  end

  def rm_path(path)
    log_info("Deleting #{path}")
    FileUtils.rm_rf(path)
  end

  def expect_path_to_repo(name)
    local = File.expand_path(File.join(".", name))
    return local if File.exist?(local)

    up_one = File.expand_path(File.join("..", name))
    return up_one if File.exist?(up_one)

    raise %Q[
Could not find repo #{name}.  Checked these two directories:

#{local}
#{up_one}

To specify a non-standard location for these repositories, use:

*   DEVICEAGENT_PATH=path/to/DeviceAgent.iOS
* IOS_DEVICE_MANAGER=path/to/iOSDeviceManager
]
  end

  def device_agent
    @device_agent_path ||= lambda do
      path = ENV["DEVICE_AGENT"] || expect_path_to_repo("DeviceAgent.iOS")
      log_info "Using DEVICEAGENT_PATH=#{path}"
      path
    end.call
  end

  def ios_device_manager
    @ios_device_manager_path ||= lambda do
      path = ENV["IOS_DEVICE_MANAGER"] || expect_path_to_repo("iOSDeviceManager")
      log_info "Using iOSDeviceManager=#{path}"
      @ios_device_manager_path = path
    end.call
  end

  def ditto(source, target)
    args = ["ditto", source, target]

    log_unix_cmd("xcrun #{args.join(" ")}")

    result = system("xcrun", *args)
    if !result
      raise %Q[Could not copy
source = #{source}
target = #{target}
]
    else
      log_info "Installed #{source} to #{target}"
    end
  end

  def ditto_zip(source, target)
    args = ["ditto", "-ck", "--rsrc", "--sequesterRsrc", "--keepParent",
            source, target]

    log_unix_cmd("xcrun #{args.join(" ")}")

    result = system("xcrun", *args)
    if !result
      raise %Q[Could not zip:
source = #{source}
target = #{target}
      ]
    else
      log_info "Installed #{source} to #{target}"
    end
  end

  def ditto_unzip(source, target)
    args = ["ditto", "-xk", source, target]

    log_unix_cmd("xcrun #{args.join(" ")}")

    result = system("xcrun", *args)
    if !result
      raise %Q[Could not unzip:
source = #{source}
target = #{target}
]
    end
  end

  def checkout(path)
    args = ["checkout", path]

    log_unix_cmd("git #{args.join(" ")}")

    result = system("git", *args)
    if !result
      raise %Q[Could not checkout: #{path}]
    end
  end

  def ensure_valid_core_simulator_service
    max_tries = 3
    valid = false
    3.times do |try|
      valid = valid_core_simulator_service?
      break if valid
      log_info("Invalid CoreSimulator service for active Xcode: try #{try + 1} of #{max_tries}")
    end
    if valid
      log_info("CoreSimulatorService is valid")
    else
      puts "CoreSimulatorService is invalid, try running again."
      exit 1
    end
  end

  def valid_core_simulator_service?
    require "run_loop/shell"
    args = ["xcrun", "simctl", "help"]

    begin
      hash = RunLoop::Shell.run_shell_command(args)
      hash[:exit_status] == 0 &&
        !hash[:out][/Failed to locate a valid instance of CoreSimulatorService/]
    rescue RunLoop::Shell::Error => _
      false
    end
  end

  def create_calabash_keychain
    require "run_loop/environment"
    path = File.join("..", "calabash-codesign")

    if !File.exist?(path)
      path = File.join(RunLoop::Environment.user_home_directory,
                       ".calabash", "calabash-codesign")
    end

    if File.exist?(path)
      Dir.chdir(path) do
        args = ["apple/create-keychain.sh"]
        hash = RunLoop::Shell.run_shell_command(args)
        if hash[:exit_status] != 0
          raise %Q[
Failed to create the codesigning keychain:

#{hash[:out]}

]
        else
          log_info("Created the Calabash.keychain")
        end
      end
    else
     log_info("Cannot create the Calabash.keychain")
    end
  end

  task :build do
    banner("Building")

    # Memoize base target directory
    device_agent_dir

    ensure_valid_core_simulator_service

    create_calabash_keychain

    Dir.chdir(ios_device_manager) do
      result = system("make", "build")
      if !result
        raise "Could not build iOSDeviceManager"
      end

      banner("Installing iOSDeviceManager to run_loop")

      ditto(File.join("Products", "iOSDeviceManager"), bin)
      ditto(File.join(".", "LICENSE"),
            File.expand_path(File.join(bin, "..", "iOSDeviceManager.LICENSE")))
      ditto_zip("Frameworks", frameworks_zip)
    end

    Dir.chdir(device_agent) do
      result = system("make", "ipa-agent")
      if !result
        raise "Could not build DeviceAgent-runner.app for physical devices"
      end

      result = system("make", "app-agent")
      if !result
        raise "Could not build DeviceAgent-runner.app for iOS Simulators"
      end

      banner("Installing DeviceAgent to run_loop")

      ditto_zip(
        File.join("Products", "app", "DeviceAgent", "DeviceAgent-Runner.app"),
        app_zip
      )

      ditto_zip(
        File.join("Products", "ipa", "DeviceAgent", "DeviceAgent-Runner.app"),
        ipa_zip
      )
    end
  end

  desc "Remove DeviceAgent binaries"
  task :clean do
    banner("Cleaning")

    log_info("Removing legacy artifacts")
    cbx_paths.each { |path| FileUtils.rm_rf(path) }

    rm_path(frameworks_dir)
    rm_path(app_dir)
    rm_path(ipa_dir)
    rm_path(frameworks_zip)
    rm_path(app_zip)
    rm_path(ipa_dir)
    rm_path(bin)
    rm_path(cli_json)
  end

  desc "Remove DeviceAgent binaries, but leave the original .zip files"
  task :uninstall do
    banner("Uninstalling")
    rm_path(frameworks_dir)
    rm_path(app_dir)
    rm_path(ipa_dir)
  end

  desc "Remove existing files and the DeviceAgent .zip files"
  task :expand do
    banner("Expanding")

    banner("Uninstalling")
    rm_path(frameworks_dir)
    rm_path(app_dir)
    rm_path(ipa_dir)

    Dir.chdir(device_agent_dir) do
      ditto_unzip(frameworks_zip, device_agent_dir)
      ditto_unzip(app_zip, File.join(device_agent_dir, "app"))
      ditto_unzip(ipa_zip, File.join(device_agent_dir, "ipa"))
    end
  end

  desc "Roll back changes to DeviceAgent binaries; does not touch client.rb"
  task :checkout do
    banner("Git Checkout")
    checkout(bin)
    checkout(frameworks_zip)
    checkout(app_zip)
    checkout(ipa_zip)
  end
end

