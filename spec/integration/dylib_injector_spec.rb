if Resources.shared.core_simulator_env?

  describe RunLoop::DylibInjector do

    let(:device) { Resources.shared.random_simulator_device }
    let(:app_bundle) { Resources.shared.app_bundle_path }
    let(:app) { RunLoop::App.new(app_bundle) }
    let(:core_sim) { RunLoop::LifeCycle::CoreSimulator.new(app, device) }
    let(:dylib) { Resources.shared.sim_dylib_path }
    let(:injector) { RunLoop::DylibInjector.new(app.executable_name, dylib) }

    before do
      stub_env({'DEBUG' => '1'})
    end

    describe '#inject_dylib_with_timeout' do
      it 'targeting the simulator' do
        core_sim.send(:launch)

        expect do
          injector.inject_dylib_with_timeout(1)
        end.to raise_error RuntimeError
      end
    end

    describe '#retriable_inject_dylib' do
      it 'targeting the simulator' do
        core_sim.send(:launch)

        vals = [false, false]
        options = { retries: vals.count + 1}
        expect(injector).to receive(:inject_dylib_with_timeout).exactly(vals.count).times.and_return(*vals)
        expect(injector).to receive(:inject_dylib_with_timeout).and_call_original

        expect(injector.retriable_inject_dylib(options)).to be == true
      end
    end
  end
end
