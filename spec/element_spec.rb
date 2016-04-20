require 'spec_helper'
# require 'pry'

describe Element do
  let(:test_element) { Element }
  let(:logger) { Log }
  let(:test_element_verification) { ElementVerification }

  describe '#verify' do
    xit 'verifies new element and logs it' do
      allow(logger).to receive(:debug)

      test_element.verify(nil)

      expect(test_element_verification).to receive(:new)
      expect(logger).to have_received(:debug).with('Verifying new element...')
    end
  end
end
