module RunLoop
  # @!visibility private
  module DetectAUT

    # @!visibility private
    module XamarinStudio

      # @!visibility private
      def xamarin_project?
        solution_directory != nil
      end

      # @!visibility private
      def solution_directory
        solution = RunLoop::Environment.solution

        if solution && !File.exist?(solution)
          raise_solution_missing(solution)
        end

        # SOLUTION defined and exists
        return File.dirname(solution) if solution

        solution_dir = find_solution_directory
        return nil if solution_dir.nil?

        solution_dir
      end

      # @!visibility private
      def find_solution_directory
        pwd = Dir.pwd
        solutions = Dir.glob("#{pwd}/*.sln")

        if solutions.empty?
          solutions = Dir.glob("#{pwd}/../*.sln")
        end

        return nil if solutions.empty?

        File.expand_path(File.dirname(solutions.first))
      end
    end
  end
end

