
describe RunLoop do

  before do
    allow_any_instance_of(RunLoop::Instruments).to receive(:instruments_app_running?).and_return(false)
  end

  let(:xcode) { RunLoop::Xcode.new }
  let(:instruments) { RunLoop::Instruments.new }
  let(:simctl) { RunLoop::Simctl.new }
  let(:device) { Resources.shared.device }

  describe ".run" do

    it "does not mangle options" do

      allow(xcode).to receive(:version_gte_8?).and_return(false)

      options = {
        :xcode => xcode,
        :simctl => simctl,
        :uia_strategy => :preferences,
        :instruments => instruments,
        :device => device
      }

      after = {
        :xcode => xcode,
        :simctl => simctl,
        :uia_strategy => :preferences,
        :instruments => instruments,
        :device => device,
      }

      expect(RunLoop::Core).to receive(:run_with_options).with(after).and_return({})
      RunLoop.run(options)

      expect(options.count).to be == 5
    end
  end

  context ".default_automator" do
    it "returns :instruments on the XTC" do
      expect(RunLoop::Environment).to receive(:xtc?).and_return(true)

      expect(RunLoop.default_automator(xcode, device)).to be == :instruments
    end

    context "not XTC" do

      before do
        expect(RunLoop::Environment).to receive(:xtc?).at_least(:once).and_return(false)
      end

      context "Xcode >= 8" do

        before do
          expect(xcode).to receive(:version_gte_8?).and_return(true)
        end

        it "returns :device_agent if device version >= 9.0" do
          ios9 = RunLoop::Version.new("9.0")
          expect(device).to receive(:version).at_least(:once).and_return(ios9)

          expect(RunLoop.default_automator(xcode, device)).to be == :device_agent
        end

        it "raises error if device version < 9.0" do
          ios8 = RunLoop::Version.new("8.0")
          expect(device).to receive(:version).at_least(:once).and_return(ios8)

          expect do
            RunLoop.default_automator(xcode, device)
          end.to raise_error RuntimeError, /Invalid Xcode and iOS combination/
        end
      end

      context "Xcode < 8" do
        it "returns :instruments" do
          expect(xcode).to receive(:version_gte_8?).and_return(false)

          expect(RunLoop.default_automator(xcode, device)).to be == :instruments
        end
      end
    end
  end

  context ".detect_automator" do
    let(:options) { {} }

    context "XTC" do
      it "returns :instruments" do
        expect(RunLoop::Environment).to receive(:xtc?).and_return(true)

        expected = :instruments
        actual = RunLoop.detect_automator(options, xcode, device)
        expect(actual).to be == expected
      end
    end

    context "not XTC" do

      before do
        expect(RunLoop::Environment).to receive(:xtc?).at_least(:once).and_return(false)
      end

      context ":automator defined" do
        context "Xcode < 8" do
          it "returns :automator value" do
            options[:automator] = :instruments
            expect(xcode).to receive(:version_gte_8?).and_return(false)

            actual = RunLoop.detect_automator(options, xcode, device)
            expect(actual).to be == :instruments
          end
        end

        context "Xcode >= 8" do
          before do
            expect(xcode).to receive(:version_gte_8?).and_return(true)
          end

          it "raises error if :instruments" do
            options[:automator] = :instruments

            expect do
              RunLoop.detect_automator(options, xcode, device)
            end.to raise_error RuntimeError,
                               /Incompatible :automator option for active Xcode/
          end

          it "raises error if iOS version < 9.0" do
            options[:automator] = :device_agent
            ios8 = RunLoop::Version.new("8.0")
            expect(device).to receive(:version).at_least(:once).and_return(ios8)

            expect do
              RunLoop.detect_automator(options, xcode, device)
            end.to raise_error RuntimeError, /Invalid Xcode and iOS combination/
          end
        end

        it "raises error if unknown automator" do
          options[:automator] = :unknown_automator

          allow(device).to receive(:version).and_return(RunLoop::Version.new("9.1"))

          expect do
            RunLoop.detect_automator(options, xcode, device)
          end.to raise_error RuntimeError, /Invalid :automator option:/
        end
      end
    end

    context ":automator not defined" do
      it "returns .default_automator" do
        expected = :automator
        expect(RunLoop).to receive(:default_automator).and_return(expected)

        expect(RunLoop.detect_automator(options, xcode, device)).to be == expected
      end
    end
  end
end
