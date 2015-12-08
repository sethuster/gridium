require 'logger_extensions'

module Gridium
  class GridiumLogger
    def initialize
      # log to STDOUT and file
      logger ||= Logger.new(STDOUT)

      # messages that have the set level or higher will be logged
      case Gridium.config.log_level
        when :debug then
          level = Logger::DEBUG
        when :info then
          level = Logger::INFO
        when :warn then
          level = Logger::WARN
        when :error then
          level = Logger::ERROR
        when :fatal then
          level = Logger::FATAL
      end

      logger.level = level

      logger.formatter = proc do |severity, datetime, progname, msg|
        base_msg = "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}][#{severity}]"
        sev = severity.to_s
        if sev.eql?("DEBUG")
          "#{base_msg}   #{msg}\n"
        elsif sev.eql?("INFO")
          "#{base_msg}  > #{msg}\n"
        elsif sev.eql?("WARN")
          "#{base_msg}  X #{msg}\n"
        else
          "#{base_msg} X #{msg}\n"
        end
      end
      logger
    end
  end
end