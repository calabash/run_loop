
describe RunLoop::DeviceAgent::Client do

  def wait_for_server_response
    output = ""
    start = Time.now
    loop do
      output = `curl --silent http://127.0.0.1:37265/version`
      break if output[/server_identifier/]
      if (Time.now - start) > 20
        output = nil
        break
      end
      sleep(1.0)
    end
    output
  end

  def server_id_from_version_route(response_body:)
    pair = response_body[/server_identifier":"[a-z0-9]+-(dirty)?/].gsub("\"", "")
    expect(pair.split(":")[1]).to be != original_server_id
  end

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  describe "Simulators" do

    let(:device) { Resources.shared.default_simulator }
    let(:workspace) { File.join(Resources.shared.resources_dir, "dylib-injection") }
    let(:dylibs_dir) { File.join(Resources.shared.resources_dir, "dylibs") }
    let(:fat_dylib) { File.join(dylibs_dir, "libCalabashFAT.dylib")}

    before do
      RunLoop::CoreSimulator.quit_simulator
      RunLoop::Simctl.new.wait_for_shutdown(device, 30, 0.1)
      FileUtils.rm_rf(workspace)
      FileUtils.mkdir_p(workspace)
    end

    describe "launch app with runtime dylib injection on simulators" do
      let(:options) do
        {
          device: device,
          xcode: Resources.shared.xcode,
          simctl: Resources.shared.simctl,
          instruments: Resources.shared.instruments
        }
      end

      describe "app not statically linked with calabash.framework" do
        let(:app) do
          path = File.join(workspace, "CalSmoke.app")
          FileUtils.cp_r(Resources.shared.app_bundle_path, path)
          RunLoop::App.new(path)
        end

        it "successfully injects dylib if INJECT_CALABASH_DYLIB is set" do
          stub_env("INJECT_CALABASH_DYLIB", fat_dylib )
          options[:app] = app
          RunLoop::DeviceAgent::Client.run(options)

          options = { :raise_on_timeout => true, :timeout => 10 }
          RunLoop::ProcessWaiter.new("CalSmoke", options).wait_for_any

          output = `curl --silent http://127.0.0.1:37265/version`
          puts output
          expect(output[/server_identifier/]).to be_truthy
        end
      end

      describe "app statically linked with calabash.framework" do
        let(:app) do
          path = File.join(workspace, "CalSmoke-cal.app")
          FileUtils.cp_r(Resources.shared.cal_app_bundle_path, path)
          RunLoop::App.new(path)
        end

        it "successfully injects dylib if INJECT_CALABASH_DYLIB is set" do
          original_server_id = app.calabash_server_id
          stub_env("INJECT_CALABASH_DYLIB", fat_dylib )

          options[:app] = app
          RunLoop::DeviceAgent::Client.run(options)

          options = { :raise_on_timeout => true, :timeout => 10 }
          RunLoop::ProcessWaiter.new("CalSmoke-cal", options).wait_for_any

          response_body = wait_for_server_response
          expect(response_body).to be_truthy

          injected_server_version = server_id_from_version_route(response_body)
          expect(injected_server_version).to be != original_server_id
        end
      end
    end

    describe "#launch" do
      let(:bundle_identifier) { "com.apple.Preferences" }

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
    end
  end
end
