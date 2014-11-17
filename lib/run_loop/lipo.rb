require 'open3'
#require 'plist_buddy'

module RunLoop

  # A class for interacting with the lipo command-line tool.
  #
  # @note All lipo commands are run in the context of `xcrun`.
  class Lipo

   def initialize(bundle_path)
     @plist_buddy = RunLoop::PlistBuddy.new
     plist_path = find_plist_path(bundle_path)
     @binary_path = find_binary_path(plist_path)
   end

   def verify_arch(list_of_archs)
      # -verify_arch list-of-arches
      # shell out to lipo and pass the binary path 
     # return a bool
   end

   def info
     # -info
     # shell out to lipo and return a list of architectures
   end

   private

   def shell_out_to_lipo(argument)
     # build the command line here

     Open3.popen3("xcrun lipo #{argument}") do |stdin, stdout, stderr, wait_thr|
       return {stdout: stdout.read.strip, stderr: stderr.read.strip, status_code: wait_thr.status.code}
     end
   end

   def find_plist_path(bundle_path)
     # inspect the bunlde path and return the path to 
   end

   def find_binary_path(plist_path)
      # return the path to the binary
      plist_path = find_plist_path
      # lookup path to binary using plist buddy
   end
  end
end
