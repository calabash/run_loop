module RunLoop

  # @!visibility private
  module LifeCycle

    # @!visibility private
    #
    # Defines a Life Cycle interface for Simulators.
    class Simulator

      # @!visibility private
      # Pattern.
      # [ '< process name >', < send term first > ]
      MANAGED_PROCESSES =
            [
                  # This process is a daemon, and requires 'KILL' to terminate.
                  # Killing the process is fast, but it takes a long time to
                  # restart.
                  # ['com.apple.CoreSimulator.CoreSimulatorService', false],

                  # Probably do not need to quit this, but it is tempting to do so.
                  #['com.apple.CoreSimulator.SimVerificationService', false],

                  # Started by Xamarin Studio, this is the parent process of the
                  # processes launched by Xamarin's interaction with
                  # CoreSimulatorBridge.
                  ['csproxy', true],

                  # Yes.
                  ['SimulatorBridge', true],
                  ['configd_sim', true],
                  ['launchd_sim', true],

                  # Does not always appear.
                  ['CoreSimulatorBridge', true],

                  # assetsd instances clobber each other and are not properly
                  # killed when quiting the simulator.
                  ['assetsd', true],

                  # Xcode 7
                  ['ids_simd', true]
            ]

      # @!visibility private
      def terminate_core_simulator_processes
        MANAGED_PROCESSES.each do |pair|
          name = pair[0]
          send_term = pair[1]
          pids = RunLoop::ProcessWaiter.new(name).pids
          pids.each do |pid|

            if send_term
              term = RunLoop::ProcessTerminator.new(pid, 'TERM', name)
              killed = term.kill_process
            else
              killed = false
            end

            unless killed
              term = RunLoop::ProcessTerminator.new(pid, 'KILL', name)
              term.kill_process
            end
          end
        end
      end
    end
  end
end
