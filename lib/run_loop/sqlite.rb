module RunLoop
  # @!visibility private
  class Sqlite

    # @!visibility private
    # MacOS ships with sqlite3
    SQLITE3 = "/usr/bin/sqlite3"

    # @!visibility private
    def self.exec(file, sql)
      if !File.exist?(file)
        raise ArgumentError,
%Q{sqlite database must exist at path:

#{file}
}
      end

      if sql.nil? || sql == ""
        raise ArgumentError, "Sql argument must not be nil or the empty string"
      end

      args = [SQLITE3, file, sql]
      hash = self.xcrun.exec(args, {:log_cmd => true})

      out = hash[:out]
      exit_status = hash[:exit_status]

			if exit_status.nil? || exit_status != 0
				raise RuntimeError,
%Q{
Could not complete sqlite operation:

file: #{file}
 sql: #{sql}
 out: #{out}

Exited with status: '#{exit_status}'
}
			end

      out
    end

    # @!visibilty private
    def self.parse(string, delimiter="|")
       if string == nil
         []
       else
         string.split(delimiter)
       end
    end

    private

    def self.xcrun
      RunLoop::Xcrun.new
    end
  end
end

