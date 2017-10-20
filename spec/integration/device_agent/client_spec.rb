
# DeviceAgent no longer builds with Xcode 7
# xcodebuild test-without-building is not available for Xcode 7
if Resources.shared.xcode.version_gte_8?
  describe RunLoop::DeviceAgent::Client do

    before do
      allow(RunLoop::Environment).to receive(:debug?).and_return(true)
    end

    describe "#launch" do
      let(:device) { Resources.shared.default_simulator }
      let(:bundle_identifier) { "com.apple.Preferences" }

      before do
        RunLoop::CoreSimulator.quit_simulator
        RunLoop::Simctl.new.wait_for_shutdown(device, 30, 0.1)
      end

      it "xcodebuild" do
        workspace = File.expand_path(File.join("..", "DeviceAgent.iOS", "DeviceAgent.xcworkspace"))
        if File.exist?(workspace)
          cbx_launcher = RunLoop::DeviceAgent::Xcodebuild.new(device)
          client = RunLoop::DeviceAgent::Client.new(bundle_identifier,
                                                    device,
                                                    cbx_launcher,
                                                    {})
          client.launch

          options = { :raise_on_timeout => true, :timeout => 5 }
          RunLoop::ProcessWaiter.new("Preferences", options).wait_for_any

          if RunLoop::Environment.ci?
            sleep(5)
          else
            sleep(1)
          end

          point = client.query_for_coordinate({marked: "General"})
          client.perform_coordinate_gesture("touch", point[:x], point[:y])
        else
          RunLoop.log_debug("Skipping :xcodebuild cbx launcher test")
          RunLoop.log_debug("Could not find a DeviceAgent.iOS repo")
        end
      end

      context "iOSDeviceManager" do

        def launch_app(device, bundle_identifier)
          cbx_launcher = RunLoop::DeviceAgent::IOSDeviceManager.new(device)
          client = RunLoop::DeviceAgent::Client.new(bundle_identifier,
                                                    device, cbx_launcher,
                                                    {})
          client.launch

          options = { :raise_on_timeout => true, :timeout => 5 }
          RunLoop::ProcessWaiter.new("Preferences", options).wait_for_any

          if RunLoop::Environment.ci?
            sleep(5)
          else
            sleep(1)
          end
          client
        end

        def touch_general_row(client)
          point = client.query_for_coordinate({marked: "General"})
          client.perform_coordinate_gesture("touch", point[:x], point[:y])
          sleep(1.0)
        end

        it "Simulator does not relaunch after it is quit" do
          client = launch_app(device, bundle_identifier)
          touch_general_row(client)

          RunLoop::CoreSimulator.quit_simulator

          20.times do
            waiter = RunLoop::ProcessWaiter.new("Simulator")
            expect(waiter.pids.empty?).to be_truthy
            sleep 1.0
          end
        end

        it "Simulator does not relaunch if next test targets same simulator" do
          client = launch_app(device, bundle_identifier)
          touch_general_row(client)

          pid = RunLoop::ProcessWaiter.new("Preferences").pids.first
          expect(pid).to be_truthy
          RunLoop::ProcessTerminator.new(pid, "TERM", "Preferences",
                                         {raise_on_no_terminate: true})

          client = launch_app(device, bundle_identifier)
          touch_general_row(client)
        end

        it "RunLoop::Client#shutdown terminates xcodebuild-Simulator process" do
          client = launch_app(device, bundle_identifier)
          touch_general_row(client)

          client.send(:shutdown)

          RunLoop::ProcessWaiter.new("xcodebuild").wait_for_none
        end

        it "next test targets a different Simulator" do
          client = launch_app(device, bundle_identifier)
          touch_general_row(client)

          version = RunLoop::Version.new("9.0")
          other_device = Resources.shared.random_simulator_device(version)
          client = launch_app(other_device, bundle_identifier)
          touch_general_row(client)
        end
      end
    end
  end
end
