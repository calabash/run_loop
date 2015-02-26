describe RunLoop::XCTools do

  subject(:xctools) { RunLoop::XCTools.new }

  describe '#instruments' do
    describe 'when argument is' do

      it ':version it returns cli version' do
        version = xctools.instruments(:version)
        expect(version >= RunLoop::Version.new('5.1')).to be true
      end

      it ':sims it returns list of installed simulators' do
        expect(xctools.instruments :sims).to be_a Array
      end

      describe ':templates it returns a list of templates for' do
        it 'the current Xcode version' do
          templates = xctools.instruments :templates
          expect(templates).to be_a Array
          expect(templates.empty?).to be false
          unless xctools.xcode_version_gte_6?
            expect(templates.all? { |path| File.exists? path }).to be == true
          end
        end

        describe 'regression' do
          xcode_installs = Resources.shared.alt_xcode_install_paths
          if xcode_installs.empty?
            it 'no alternative versions of Xcode found' do
              expect(true).to be == true
            end
          else
            xcode_installs.each do |developer_dir|
              it "#{developer_dir}" do
                Resources.shared.with_developer_dir(developer_dir) do
                  templates = xctools.instruments :templates
                  expect(templates).to be_a Array
                  expect(templates.empty?).to be false
                  unless xctools.xcode_version_gte_6?
                    expect(templates.all? { |path| File.exists? path }).to be == true
                  end
                end
              end
            end
          end
        end
      end

      it ':devices it returns a list of iOS devices' do
        devices = xctools.instruments :devices
        expect(devices).to be_a Array
        unless devices.empty?
          expect(devices.all? { |device| device.is_a? RunLoop::Device }).to be == true
        end
      end
    end
  end
end
