require 'spec_helper'

describe RunLoop::Core do
  describe '.default_tracetemplate' do
    it 'should always return a template' do
      expect(RunLoop::Core.default_tracetemplate).not_to be nil
    end
  end
end
