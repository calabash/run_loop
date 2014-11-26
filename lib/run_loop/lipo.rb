require 'open3'

module RunLoop

  # A class for interacting with the lipo command-line tool to verify that an
  # executable is valid for the test target (device or simulator).
  #
  # @note All lipo commands are run in the context of `xcrun`.
  class Lipo

   attr_accessor :bundle_path

   def initialize(bundle_path)
     @bundle_path = bundle_path
     @plist_buddy = RunLoop::PlistBuddy.new
   end

   # Is the target architecture compatible with executable in the application
   # bundle?
   #
   # @param [Symbol] target_arch An architecture, like :armv7, :i386, or :armv64
   # @return [Boolean] Returns true if the `target_arch` can be found in the
   #  executable.
   def verify_arch(target_arch)

   end

   # Returns a list of architecture in the binary.
   # @return [Array<String>] A list of architecture.
   def info
     execute_lipo("-info #{binary_path}") do |stdout, _, _|
       output = stdout.read.strip
       output.split(':')[-1].strip.split
     end
   end

   private

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
