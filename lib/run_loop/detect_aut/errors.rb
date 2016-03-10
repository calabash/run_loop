module RunLoop

  # @!visibility private
  class SolutionMissingError < RuntimeError ; end

  # @!visibility private
  class XcodeprojMissingError < RuntimeError; end

  # @!visibility private
  class MultipleXcodeprojError < RuntimeError; end

  # @!visibility private
  class NoSimulatorAppFoundError < RuntimeError; end

  # @!visibility private
  module DetectAUT

    # @!visibility private
    module Errors

      # @!visibility private
      #
      # Raised when XCODEPROJ is defined, but does not exist
      def raise_xcodeproj_missing(xcodeproj)
        raise RunLoop::XcodeprojMissingError,
%Q[The XCODEPROJ environment variable has been set to:

#{xcodeproj}

but no directory exists at that path.

You should only set XCODEPROJ variable if your Calabash project has more than
one .xcodeproj directory or your .xcodeproj directory is located above the
current directory (where you run `cucumber` from).  Calabash will discover the
.xcodeproj if is below the current working directory.

# .xcodeproj is above the working directory
$ ls ../*.xcodeproj
MyApp.xcodeproj

$ XCODEPROJ=../*.xcodeproj cucumber

# There is more than one .xcodeproj
$ ls *.xcodeproj
MyiOSApp.xcodeproj
MyMacApp.xcodeproj

$ XCODEPROJ=MyiOSApp.xcodeproj
]
      end

      # @!visibility private
      #
      # Raised when there are more than > 1 .xcodeproj in **/*
      # Is not raised when there are 0 .xcodeproj in **/*
      #
      # @param [Array<String>] projects a list of paths to .xcodeproj
      def raise_multiple_xcodeproj(projects)
      raise RunLoop::MultipleXcodeprojError,
%Q[Found multiple .xcodeproj directories:

#{projects.join($-0)}

Which project contains the target of the application you are trying to test?

Set the XCODEPROJ variable to specify the correct .xcodeproj directory.

# Examples
$ XCODEPROJ="../MyApp.xcodeproj" cucumber
$ XCODEPROJ="iOS/MyApp.xcodeproj" cucumber
]
      end

      # @!visibility private
      #
      # Raised when SOLUTION is defined but does not exist
      def raise_solution_missing(solution)
        raise RunLoop::SolutionMissingError,
%Q[The SOLUTION environment variable has been set to:

#{solution}

but no solution exists at that path.

You should only set SOLUTION variable if your .sln is not located in
the current directory or in the directory just above the current
directory (where you run `cucumber` from). Calabash will discover the
.snl if it is in the current working directory or the directory just
above.

# Calabash will discover solution - don't set SOLUTION
$ ls *.sln => MyApp.sln
$ ls ../*.sln => MyApp.sln

# Calabash will _not_ discover solution
$ ls ../../*.sln => MyApp.sln
$ SOLUTION=../../MyApp.sln cucumber

$ ls project/*.sln => MyApp.sln
$ SOLUTION=project/MyApp.sln cucumber

$ ls ~/some/other/directory/*.sln => MyApp.sln
$ SOLUTION=~/some/other/directory/MyApp.sln
]
      end

      # @!visibility private
      # Raised when no app can found by the discovery algorithm
      def raise_no_simulator_app_found(search_directories, search_depth)
        raise RunLoop::NoSimulatorAppFoundError,
%Q[Recursively searched these directories to depth #{search_depth}:

#{search_directories.join($-0)}

but could not find any .app for the simulator that links the Calabash iOS server.

Make sure you have built your app for a simulator target from Xcode.

If you are testing a stand-alone .app (you don't have an Xcode project), put
your .app in the same directory (or below) the directory you run `cucumber` from.
]
      end
    end
  end
end

