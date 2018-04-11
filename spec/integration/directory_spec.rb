
describe RunLoop::Directory do
  let(:app_path) { Resources.shared.app_bundle_path }

  context ".directory_digest" do
    let(:tmpdir) { File.join(Resources.shared.local_tmp_dir, "digest") }

    before do
      FileUtils.rm_rf(tmpdir)
      FileUtils.mkdir_p(tmpdir)
    end

    it "returns the same digest after ditto" do
      original_digest = RunLoop::Directory.directory_digest(app_path)

      copy_path = File.join(tmpdir, "App-copy.app")
      RunLoop::Shell.run_shell_command(["ditto", app_path, copy_path])
      copy_digest = RunLoop::Directory.directory_digest(copy_path)

      expect(original_digest).to be == copy_digest
    end

    it "returns the same digest after 'xcrun install'" do
      app = RunLoop::App.new(app_path)
      original_digest = RunLoop::Directory.directory_digest(app_path)

      device = Resources.shared.default_simulator
      core_sim = RunLoop::CoreSimulator.new(device, app)
      core_sim.uninstall_app_and_sandbox
      core_sim.install

      installed_path = core_sim.send(:installed_app_bundle_dir)
      installed_digest = RunLoop::Directory.directory_digest(installed_path)

      expect(original_digest).to be == installed_digest
    end
  end
end