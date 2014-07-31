describe 'Version' do

  describe '.new' do
    describe 'non-pre-release versions' do
      subject(:version) { RunLoop::Version.new('0.9.169') }
      it { expect(version).not_to be nil }
      it { expect(version.major).to be == 0 }
      it { expect(version.minor).to be == 9 }
      it { expect(version.patch).to be == 169 }
      it { expect(version.pre).to be nil }
      it { expect(version.pre_version).to be nil }
    end

    describe 'unnumbered pre-release versions' do
      subject(:version) { RunLoop::Version.new('0.9.169.pre') }
      it { expect(version.pre).to be == 'pre' }
      it { expect(version.pre_version).to be nil }
    end

    describe 'numbered pre-release versions' do
      subject(:version) { RunLoop::Version.new('0.9.169.pre1') }
      it { expect(version.pre).to be == 'pre1' }
      it { expect(version.pre_version).to be == 1 }
    end

    describe 'invalid arguments' do
      it { expect { RunLoop::Version.new(' ') }.to raise_error ArgumentError }
      it { expect { RunLoop::Version.new('5.1.pre3') }.to raise_error ArgumentError }
      it { expect { RunLoop::Version.new('5.pre2') }.to raise_error ArgumentError }
    end
  end

  describe '==' do
    it 'tests equality' do
      a = RunLoop::Version.new('0.9.5')
      b = RunLoop::Version.new('0.9.5')
      expect(a == b).to be true

      a = RunLoop::Version.new('0.9.5.pre')
      b = RunLoop::Version.new('0.9.5.pre')
      expect(a == b).to be true

      a = RunLoop::Version.new('0.9.5.pre1')
      b = RunLoop::Version.new('0.9.5.pre1')
      expect(a == b).to be true

      a = RunLoop::Version.new('0.9.5.pre')
      b = RunLoop::Version.new('0.9.5.pre1')
      expect(a == b).to be false

    end
  end

  describe '!=' do
    it 'tests not equal' do
      a = RunLoop::Version.new('0.9.4')
      b = RunLoop::Version.new('0.9.5')
      expect(a != b).to be true

      a = RunLoop::Version.new('0.9.5')
      b = RunLoop::Version.new('0.9.5.pre')
      expect(a != b).to be true

      a = RunLoop::Version.new('0.9.5.pre')
      b = RunLoop::Version.new('0.9.5.pre1')
      expect(a != b).to be true

      a = RunLoop::Version.new('0.9.5.pre1')
      b = RunLoop::Version.new('0.9.5.pre2')
      expect(a != b).to be true
    end
  end

  describe '<' do
    it 'tests less than' do
      a = RunLoop::Version.new('0.9.4')
      b = RunLoop::Version.new('0.9.5')
      expect(a < b).to be true

      a = RunLoop::Version.new('0.9.5')
      b = RunLoop::Version.new('0.9.5.pre')
      expect(a < b).to be true

      a = RunLoop::Version.new('0.9.5.pre')
      b = RunLoop::Version.new('0.9.5.pre1')
      expect(a < b).to be true

      a = RunLoop::Version.new('0.9.5.pre1')
      b = RunLoop::Version.new('0.9.5.pre2')
      expect(a < b).to be true
    end
  end

  describe '>' do
    it 'tests greater than' do
      a = RunLoop::Version.new('0.9.4')
      b = RunLoop::Version.new('0.9.5')
      expect(b > a).to be true

      a = RunLoop::Version.new('0.9.5')
      b = RunLoop::Version.new('0.9.5.pre')
      expect(b > a).to be true

      a = RunLoop::Version.new('0.9.5.pre')
      b = RunLoop::Version.new('0.9.5.pre1')
      expect(b > a).to be true

      a = RunLoop::Version.new('0.9.5.pre1')
      b = RunLoop::Version.new('0.9.5.pre2')
      expect(b > a).to be true
    end
  end

  describe '<=' do
    it 'tests less-than or equal' do
      a = RunLoop::Version.new('0.9.4')
      b = RunLoop::Version.new('0.9.5')
      expect(a <= b).to be true
      a = RunLoop::Version.new('0.9.5')
      expect(a <= b).to be true
    end
  end

  describe '>=' do
    it 'tests less-than or equal' do
      a = RunLoop::Version.new('0.9.4')
      b = RunLoop::Version.new('0.9.5')
      expect(b >= a).to be true
      a = RunLoop::Version.new('0.9.5')
      expect(b >= a).to be true
    end
  end

  describe '.compare' do
    subject(:a) {  RunLoop::Version.new('6.0')  }
    it 'works if there is no patch level' do
      b = RunLoop::Version.new('5.1.1')
      expect(RunLoop::Version.compare(a, b)).to be  == 1
      expect(RunLoop::Version.compare(b, a)).to be  == -1
    end

    it 'works if there is no minor level' do
      b = RunLoop::Version.new('5')
      expect(RunLoop::Version.compare(a, b)).to be == 1
      expect(RunLoop::Version.compare(b, a)).to be == -1
    end
  end
end
