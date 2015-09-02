require 'open3'

module RunLoop

  # An error class for signaling an incompatible architecture.
  class IncompatibleArchitecture < StandardError
  end

  # A class for interacting with the lipo command-line tool to verify that an
  # executable is valid for the test target (device or simulator).
  #
  # @note All lipo commands are run in the context of `xcrun`.
  class Lipo

    # The path to the application bundle we are inspecting.
    # @!attribute [wr] bundle_path
    # @return [String] The path to the application bundle (.app).
    attr_accessor :bundle_path

    def initialize(bundle_path)
      @bundle_path = bundle_path
      @plist_buddy = RunLoop::PlistBuddy.new
    end

    # @!visibility private
    def to_s
      "#<Lipo #{bundle_path}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # Inspect the `CFBundleExecutable` in the app bundle path with `lipo` and
    # compare the result with the target device's instruction set.
    #
    # **Simulators**
    #
    # If the target is a simulator and the binary contains an i386 slice, the
    # app will launch on the 64-bit simulators.
    #
    # If the target is a simulator and the binary contains _only_ an x86_64
    # slice, the app will not launch on these simulators:
    #
    # ```
    # iPhone 4S, iPad 2, iPhone 5, and iPad Retina.
    # ```
    #
    # All other simulators are 64-bit.
    #
    # **Devices**
    #
    # @see {https://www.innerfence.com/howto/apple-ios-devices-dates-versions-instruction-sets}
    #
    # ```
    # armv7  <== 3gs, 4s, iPad 2, iPad mini, iPad 3, iPod 3, iPod 4, iPod 5
    # armv7s <== 5, 5c, iPad 4
    # arm64  <== 5s, 6, 6 Plus, Air, Air 2, iPad Mini Retina, iPad Mini 3
    # ```
    #
    # @note At the moment, we are focusing on simulator compatibility.  Since we
    #  don't have an automated way of installing an .ipa on local device, we
    #  don't require an .ipa path.  Without an .ipa path, we cannot verify the
    #  architectures.  Further, we would need to adopt a third-party tool like
    #  ideviceinfo to find the target device's instruction set.
    # @param [RunLoop::Device] device The test target.
    # @raise [RuntimeError] Raises an error if the device is a physical device.
    # @raise [RunLoop::IncompatibleArchitecture] Raises an error if the instruction set of the target
    #   device is not compatible with the executable in the application.
    def expect_compatible_arch(device)
      if device.physical_device?
        raise 'Ensuring compatible arches for physical devices is NYI'
      else
        arches = self.info
        # An i386 binary will run on any simulator.
        return true if arches.include?('i386')

        instruction_set = device.instruction_set
        unless arches.include?(instruction_set)
          raise RunLoop::IncompatibleArchitecture,
                ['Binary at:',
                 binary_path,
                 'does not contain a compatible architecture for target device.',
                 "Expected '#{instruction_set}' but found #{arches}."].join("\n")
        end
      end
    end

    # Returns a list of architecture in the binary.
    # @return [Array<String>] A list of architecture.
    # @raise [RuntimeError] If the output of lipo cannot be parsed.
    def info
      execute_lipo("-info \"#{binary_path}\"") do |stdout, stderr, wait_thr|
        output = stdout.read.strip
        begin
          output.split(':')[-1].strip.split
        rescue StandardError => e
          msg = ['Expected to be able to parse the output of lipo.',
                 "cmd:    'lipo -info \"#{binary_path}\"'",
                 "stdout: '#{output}'",
                 "stderr: '#{stderr.read.strip}'",
                 "exit code: '#{wait_thr.value}'",
                 e.message]
          raise msg.join("\n")
        end
      end
    end

    private

    # Caller is responsible for correctly escaping arguments.
    # For example, the caller must proper quote `"` paths to avoid errors
    # when dealing with paths that contain spaces.
    # @todo #execute_lipo should take an [] of arguments
    def execute_lipo(argument)
      command = "xcrun lipo #{argument}"
      Open3.popen3(command) do |_, stdout, stderr, wait_thr|
        yield stdout, stderr, wait_thr
      end
    end

    def plist_path
      File.join(@bundle_path, 'Info.plist');
    end

    def binary_path
      binary_relative_path = @plist_buddy.plist_read('CFBundleExecutable', plist_path)
      File.join(@bundle_path, binary_relative_path)
    end
  end
end
