module RunLoop

  # Class for performing operations on directories.
  class Directory

    # Dir.glob ignores files that start with '.', but we often need to find
    # dotted files and directories.
    #
    # Ruby 2.* does the right thing by ignoring '..' and '.'.
    #
    # Ruby < 2.0 includes '..' and '.' in results which causes problems for some
    # of run-loop's internal methods.  In particular `reset_app_sandbox`.
    def self.recursive_glob_for_entries(base_dir)
      Dir.glob("#{base_dir}/{**/.*,**/*}").select do |entry|
        !(entry.end_with?('..') || entry.end_with?('.'))
      end
    end
  end
end
