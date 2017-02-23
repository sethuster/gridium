require 'spec_helper'
# require 'pry'

describe Log do
  let(:test_logger) { Log }
  let(:log_message) { 'Logging message' }

  describe '#debug' do
    it 'returns a debug log message' do
      expect(test_logger).to receive(:debug).with(log_message)

      test_logger.debug(log_message)
    end
  end

  describe '#info' do
    it 'returns an info log message' do
      expect(test_logger).to receive(:info).with(log_message)

      test_logger.info(log_message)
    end
  end

  describe '#warn' do
    it 'returns a warning message and puts it in execution warnings' do
      expect(test_logger).to receive(:warn).with(log_message)

      test_logger.warn(log_message)
    end
  end

  describe '#error' do
    it 'returns an error message and puts it in verification errors' do
      expect(test_logger).to receive(:error).with(log_message)

      test_logger.error(log_message)
    end
  end
end
