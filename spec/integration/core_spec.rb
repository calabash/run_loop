require 'tmpdir'

describe RunLoop::Core do

  describe '.automation_template' do

    it 'ignores the TRACE_TEMPLATE env var if the tracetemplate does not exist' do
      tracetemplate = '/tmp/some.tracetemplate'
      expect(RunLoop::Environment).to receive(:trace_template).and_return(tracetemplate)
      instruments = Resources.shared.instruments
      xcode = Resources.shared.xcode

      actual = RunLoop::Core.automation_template(instruments)
      expect(actual).not_to be == nil
      expect(actual).not_to be == tracetemplate
      if xcode.beta?
        expect(actual[/Automation.tracetemplate/, 0]).to be_truthy
      else
        expect(actual).to be == 'Automation'
      end
    end
  end

  describe '.default_tracetemplate' do
    describe 'returns a template for' do
      xcode = Resources.shared.xcode

      it "Xcode #{xcode.version}" do
        instruments = Resources.shared.instruments

        if xcode.version_gte_8?
          expect do
            RunLoop::Core.default_tracetemplate(instruments)
          end.to raise_error RuntimeError,
                             /There is no Automation template for this/
        else
          default_template = RunLoop::Core.default_tracetemplate(instruments)
          if xcode.beta?
            expect(File.exist?(default_template)).to be true
          else
            expect(default_template).to be == 'Automation'
          end
        end
      end

      describe 'regression' do
        xcode_installs = Resources.shared.alt_xcode_details_hash
        if xcode_installs.empty?
          it 'no alternative versions of Xcode found' do
            expect(true).to be == true
          end
        else
          xcode_installs.each do |xcode_details|
            it "#{xcode_details[:path]} - #{xcode_details[:version]}" do
              Resources.shared.with_developer_dir(xcode_details[:path]) {

                instruments = RunLoop::Instruments.new

                if instruments.xcode.version_gte_8?
                  expect do
                    RunLoop::Core.default_tracetemplate(instruments)
                  end.to raise_error RuntimeError,
                                     /There is no Automation template for this/
                else
                  default_template = RunLoop::Core.default_tracetemplate(instruments)
                  internal_xcode = RunLoop::Xcode.new
                  if internal_xcode.beta?
                    expect(File.exist?(default_template)).to be true
                  else
                    expect(default_template).to be == 'Automation'
                  end
                end
              }
            end
          end
        end
      end
    end
  end
end
