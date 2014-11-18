require 'open3'

module RunLoop

  # A class for interacting with the lipo command-line tool.
  #
  # @note All lipo commands are run in the context of `xcrun`.
  class Lipo

   attr_accessor :bundle_path

   def initialize(bundle_path)
     @bundle_path = bundle_path
     @plist_buddy = RunLoop::PlistBuddy.new
   end

   def verify_arch(list_of_archs)
      # -verify_arch list-of-arches
      # shell out to lipo and pass the binary path 
     # return a bool
   end

   def info
     execute_lipo("-info #{binary_path}") do |stdin, stdout, stderr, wait_thr| 
       # WIP
       stdin.split('architectures:')[1]
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
     File.join(@bundle_path, binary_relative_path);
   end
  end
end
