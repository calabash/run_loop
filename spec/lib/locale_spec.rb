
describe RunLoop::Locale do

  let(:locale) { RunLoop::Locale.new("code", "name") }
  it ".new" do
    expect(locale.code).to be == "code"
    expect(locale.instance_variable_get(:@code)).to be == "code"
    expect(locale.name).to be == "name"
    expect(locale.instance_variable_get(:@name)).to be == "name"
  end

  it ".to_s" do
    str = locale.to_s
    expect(str[/\(#{locale.code}\)/, 0]).to be_truthy
    expect(str[/#{locale.name}/, 0]).to be_truthy
    puts str
  end

  it ".inspect" do
    expect(locale).to receive(:to_s).and_call_original
    puts locale.inspect
  end

  describe ".valid_locales" do
    let (:ios110) { RunLoop::Version.new("11.0") }
    let (:ios100) { RunLoop::Version.new("10.0") }
    let (:ios91) { RunLoop::Version.new("9.1") }
    let (:ios90) { RunLoop::Version.new("9.0") }
    let (:ios80) { RunLoop::Version.new("8.0") }

    it "uses the major version" do
      ios91_locales = RunLoop::Locale.valid_locales(ios91)
      ios90_locales = RunLoop::Locale.valid_locales(ios90)

      expect(ios91_locales.count).to be == 731
      expect(ios90_locales.count).to be == ios91_locales.count
    end

    it "supports iOS 11" do
      locales = RunLoop::Locale.valid_locales(ios110)
      expect(locales.count).to be == 789
    end

    it "supports iOS 10" do
      locales = RunLoop::Locale.valid_locales(ios100)

      expect(locales.empty?).to be_falsey
      expect(locales.count).to be == 739
    end

    it "supports iOS 9" do
      locales = RunLoop::Locale.valid_locales(ios90)

      expect(locales.empty?).to be_falsey
      expect(locales.count).to be == 731
    end

    it "supports iOS 8" do
      locales = RunLoop::Locale.valid_locales(ios80)

      expect(locales.empty?).to be_falsey
      expect(locales.count).to be == 689
    end

    it "supports no other iOS version" do
      expect do
        RunLoop::Locale.valid_locales(RunLoop::Version.new("7.0"))
      end.to raise_error ArgumentError, /There are no locales for iOS version/
    end

    describe ".locale_for_code" do
      describe "raises errors" do
        it "iOS version of device arg is not supported" do
          device = RunLoop::Device.new("name", "7.0", "udid")
          expect do
            RunLoop::Locale.locale_for_code("en", device)
          end.to raise_error ArgumentError, /There are no locales for iOS version/
        end

        it "locale does not exist" do
          device = RunLoop::Device.new("name", "8.0", "udid")
          expect do
            RunLoop::Locale.locale_for_code("xyz", device)
          end.to raise_error ArgumentError, /There are no locales with code 'xyz' for iOS version/
        end
      end

      it "returns a locale object" do
        device = RunLoop::Device.new("name", "8.0", "udid")
        locale = RunLoop::Locale.locale_for_code("en", device)

        expect(locale.name).to be == "English"
        expect(locale.code).to be == "en"
      end
    end
  end
end

