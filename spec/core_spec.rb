require 'spec_helper'

describe RunLoop::Core do
  describe '.default_tracetemplate' do
    it 'should always return a template' do
      default_template = RunLoop::Core.default_tracetemplate
      expect(default_template).not_to be nil
      expect(File.exist?(default_template)).to be true
    end
  end
end
