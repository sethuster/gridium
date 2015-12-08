require 'gridium_logger'
require 'spec_data'

# Singleton Logger class
module Gridium
  class Log
    class << self

      def debug(msg)
        log.debug(msg)
      end

      def info(msg)
        log.info(msg)
      end

      def warn(msg)
        log.warn(msg)
        Driver.save_screenshot('warning') if Gridium.config.screenshot_on_failure
        SpecData.execution_warnings << msg
      end

      def error(msg)
        log.error(msg)
        Driver.save_screenshot('error') if Gridium.config.screenshot_on_failure
        SpecData.verification_errors << msg
      end

      def add_device device
        @@devices ||= []
        log.attach(device)
        @@devices << device
      end

      def close
        @@devices.each { |dev| log.detach(dev) }
        @@devices.clear
        log.close if log
      end

      private

      def log
        @logger ||= GridiumLogger.new
      end
    end
  end
end