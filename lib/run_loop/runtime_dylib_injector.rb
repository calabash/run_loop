
module RunLoop
  class RuntimeDylibInjector

    # TODO
    #
    # Dylib injection modifies the .app bundle; should we cache the original?
    #
    # Can we optimize injection by caching an app?
    #
    # We need a place in the .dot directory for the latest dylibs from
    # blob storage.
    #

    require "fileutils"
    require "run_loop/app"

    # @!visibility private
    def self.is_calabash_dylib?(path)
      !File.basename(path)[/libCalabash.*\.dylib/].nil?
    end

    # @!visibility private
    def self.dylib_from_env
      path = RunLoop::Environment.inject_calabash_dylib
      return nil if path.nil?
      return path if File.exist?(path)
      message = <<~EOS
        INJECT_CALABASH_DYLIB is set, but file does not exist
 
        #{path}
      EOS
      raise(message)
    end

    # The app to inject into
    attr_reader :app

    # The App Under Test process environment variables
    attr_reader :aut_env

    # My.app/libCalabashFAT.dylib => @executable_path/libCalabashFAT.dylib
    # My.app/Frameworks/libCalabashFAT.dylib => @executable_path/Frameworks/libCalabashFAT.dylib
    attr_reader :embedded_dylib_exec_path

    # @!visibility private
    def initialize(app, app_env)
      @app = app
      @aut_env = app_env
    end

    def to_s
      "#<RuntimeDylibInjector for #{app}>"
    end

    def inspect
      to_s
    end

    # If conditions are right, inject a Calabash dylib into the .app and modify
    # the app env so this Calabash starts when the app is launched.
    #
    # If the conditions are not right, no destructive operations are performed.
    #
    # Destructive on the .app bundle: could copy files into the bundle
    # Destructive on the app_env passed to the initializer: could add or update
    #   values
    def maybe_perform_injection!
      RunLoop.log_debug("Determining how and if to dynamically insert Calabash")
      if app.calabash_server_version
        RunLoop.log_debug("App contains an embedded (statically linked or dylib) Calabash server")
        if app.calabash_server_id
          RunLoop.log_debug("calabash.framework was linked at compile time")
          maybe_inject_and_override_statically_linked_server!
        else
          RunLoop.log_debug(".app bundle contains Calabash dylib")
          maybe_inject_by_replacing_existing_dylib_in_app_bundle!
        end
      else
        RunLoop.log_debug("Calabash is not embedded (statically linked or as a dylib) in the app")
        maybe_inject_by_adding_dylib_to_app_bundle!
      end
    end

    # @!visibility private
    def maybe_inject_and_override_statically_linked_server!
      dylib_path_from_env = RuntimeDylibInjector.dylib_from_env

      if dylib_path_from_env.nil?
        RunLoop.log_debug("INJECT_CALABASH_DYLIB not set, will not inject dylib")
        return
      end

      # server id will be truthy because there is no dylib in the .app bundle
      # which means the embedding was done at compile time.
      set_skip_lpserver_token!

      if simulator?
        import_dylib_into_app!(dylib_path_from_env)
        RunLoop.log_debug("App is for the simulator, so resigning is not necessary")
        return
      end

      # physical device
      raise "WIP: need to inject and resign with iOSDeviceManager"
    end

    # @!visibility private
    def maybe_inject_by_replacing_existing_dylib_in_app_bundle!
      dylib_path_from_env = RuntimeDylibInjector.dylib_from_env

      if dylib_path_from_env.nil?
        # The .app contains a dylib already.
        #
        # Only the DYLD_INSERT_LIBRARIES env var needs to be updated.
        RunLoop.log_debug("INJECT_CALABASH_DYLIB not set, will not inject dylib")

        if physical_device?
          RunLoop.log_debug("Assuming that the dylib and .app bundle have been resigned")
        end
        append_dyld_insert_libraries!(embedded_dylib_exec_path)
        return
      end

      if simulator?
        import_dylib_into_app!(dylib_path_from_env)
        RunLoop.log_debug("App is for the simulator, so resigning is not necessary")
        return
      end

      # physical device
      raise "WIP: need to inject and resign with iOSDeviceManager"
    end

    # @!visibility private
    def maybe_inject_by_adding_dylib_to_app_bundle!
      dylib_path_from_env = RuntimeDylibInjector.dylib_from_env

      if dylib_path_from_env.nil?
        RunLoop.log_debug("INJECT_CALABASH_DYLIB not set: will not inject dylib")
        RunLoop.log_debug("App contains no embedded Calabash server")
        raise "WIP: pull from Azure Blob Storage"
      end

      if simulator?
        import_dylib_into_app!(dylib_path_from_env)
        RunLoop.log_debug("App is for the simulator, so resigning is not necessary")
        return
      end

      # physical device
      raise "WIP: need to inject and resign with iOSDeviceManager"
    end

    # @!visibility private
    def append_dyld_insert_libraries!(path)
      key = "DYLD_INSERT_LIBRARIES"
      value = aut_env[key]
      if value
        aut_env[key] = "#{value}:#{path}"
      else
        aut_env[key] = path
      end
      RunLoop.log_debug("Updated app_env: #{key} => #{aut_env[key]}")
    end

    # @!visibility private
    def set_skip_lpserver_token!
      key = "XTC_SKIP_LPSERVER_TOKEN"
      aut_env[key] = app.calabash_server_id
      RunLoop.log_debug("Update app_env: #{key} => #{aut_env[key]}")
    end

    # @!visibility private
    # If there is an embedded calabash dylib, then return true
    #
    # App#embedded_dylib_exec_path => {true, @executable_path/<path> | false, nil}
    #  - raises an error if > 1 dylib
    def embedded_dylib_exec_path
      @embedded_dylib_exec_path ||= begin
        matches = app.executables.select do |path|
          RuntimeDylibInjector.is_calabash_dylib?(path)
        end

        case matches.count
        when 0
          RunLoop.log_debug("App does not contain Calabash dylib")
          nil
        when 1
          RunLoop.log_debug("App contains Calabash dylib")
          "@executable_path/#{matches[0].split(".app/").last}"
        else
          message = <<~EOS
          App contains more than one Calabash dylib
          
          #{matches.each {|match| puts match}}

          Only one Calabash dylib is allowed.
          EOS
          raise(message)
        end
      end
    end

    # @!visibility private
    #
    # Destructive on the file system - adds file to the .app
    # Destructive on this class
    # - sets the @embedded_dylib_exec_path
    # - updates the DYLD_INSERT_LIBRARIES value
    def import_dylib_into_app!(dylib_path)
      #noinspection RubyArgCount
      FileUtils.cp(dylib_path, app.path)
      exec_path = "@executable_path/#{File.basename(dylib_path)}"
      @embedded_dylib_exec_path = exec_path
      append_dyld_insert_libraries!(exec_path)
      exec_path
    end
  end
end